"""Optional live quality checks. Run with manage.py test core.quality_live."""
import json
import math
from concurrent.futures import ThreadPoolExecutor
from secrets import token_urlsafe
from threading import Barrier
from time import perf_counter
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from django.core.servers.basehttp import ThreadedWSGIServer
from django.test.testcases import LiveServerThread
from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from playwright.sync_api import expect, sync_playwright
from rest_framework_simplejwt.tokens import AccessToken

from accounts.models import User
from core.models import AuditEvent
from farms.models import Farm


class QualityHTTPServer(ThreadedWSGIServer):
    # Accept the entire 20-client burst before dispatching individual requests.
    request_queue_size = 64


class QualityServerThread(LiveServerThread):
    server_class = QualityHTTPServer


class LiveQualityTests(StaticLiveServerTestCase):
    host = '127.0.0.1'
    server_thread_class = QualityServerThread

    def test_admin_audit_keyboard_journey(self):
        password = token_urlsafe(24)
        admin = User.objects.create_superuser('auditor', 'qa@example.invalid', password)
        owner = User.objects.create_user('orchard_owner')
        farm = Farm.objects.create(owner=owner, name='Orchard', total_area=3)
        event = AuditEvent.objects.create(actor=owner, entity='farms.Farm', object_id=farm.pk, action='create')
        with sync_playwright() as playwright:
            for engine in ('chromium', 'firefox'):
                with self.subTest(engine=engine):
                    browser = getattr(playwright, engine).launch()
                    try:
                        page = browser.new_page()
                        page.goto(self.live_server_url + '/admin/core/auditevent/')
                        username = page.get_by_label('Username')
                        username.fill(admin.username)
                        username.press('Tab')
                        secret = page.get_by_label('Password')
                        expect(secret).to_be_focused()
                        secret.fill(password)
                        secret.press('Enter')
                        row = page.locator(f'tr:has(a[href$="/{event.pk}/change/"])')
                        expect(row).to_contain_text('orchard_owner')
                        expect(row).to_contain_text('farms.Farm')
                        expect(row).to_contain_text('create')
                        print(f'{engine} {browser.version}: keyboard login and audit row verified')
                    finally:
                        browser.close()

    def test_unauthenticated_http_response(self):
        with self.assertRaises(HTTPError) as caught:
            urlopen(self.live_server_url + '/api/dashboard/', timeout=10)
        with caught.exception as response:
            self.assertEqual(response.code, 401)
            self.assertEqual(response.headers['X-Content-Type-Options'], 'nosniff')
            self.assertEqual(response.headers['X-Frame-Options'], 'DENY')
            print('HTTP 401, nosniff and DENY verified on protected dashboard')

    def test_dashboard_load(self):
        clients = 20
        gate = Barrier(clients, timeout=30)
        requests = []
        for index in range(clients):
            owner = User.objects.create_user(f'owner-{index}', f'owner-{index}@example.invalid')
            Farm.objects.create(owner=owner, name='Olives', total_area=10)
            token = AccessToken.for_user(owner)
            requests.append(Request(self.live_server_url + '/api/dashboard/',
                                    headers={'Authorization': f'Bearer {token}'}))

        def visit(request):
            gate.wait()
            durations = []
            for _ in range(5):
                begin = perf_counter()
                with urlopen(request, timeout=30) as response:
                    self.assertEqual(json.load(response)['farms'], 1)
                durations.append((perf_counter() - begin) * 1000)
            return durations

        with ThreadPoolExecutor(max_workers=clients) as pool:
            start = perf_counter()
            samples = sorted(t for group in pool.map(visit, requests) for t in group)
            duration = perf_counter() - start
        p95 = samples[math.ceil(len(samples) * .95) - 1]
        print(f'Dashboard: {clients} owners, 20 farms, {len(samples)} successful requests, '
              f'{duration:.2f}s, {len(samples)/duration:.1f} req/s, p95 {p95:.1f} ms; target <500 ms')
        self.assertLess(p95, 500)


