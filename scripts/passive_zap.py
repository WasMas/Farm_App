"""Observe the demo owner's normal browser traffic with a local passive ZAP proxy."""
import json
import os
import shutil
import secrets
import subprocess
import tempfile
import time
from contextlib import ExitStack
from datetime import datetime, timezone
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from urllib.error import URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import ProxyHandler, build_opener

from playwright.sync_api import expect, sync_playwright


def stop(process):
    if process.poll() is None:
        if os.name == 'nt':
            subprocess.run(['taskkill', '/T', '/F', '/PID', str(process.pid)], capture_output=True)
        else:
            process.terminate()
        try:
            process.wait(timeout=12)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def prepare_web_build(root, api, web_build):
    if web_build is not None:
        site = web_build.resolve(strict=True)
        if not (site / 'index.html').is_file():
            raise ValueError(f'Missing Flutter web entry point in {site}')
        return site

    site = root / '.local/zap-web'
    subprocess.run([shutil.which('flutter') or 'flutter', 'build', 'web', '--release',
                    '--no-web-resources-cdn', f'--output={site}', f'--dart-define=API_BASE_URL={api}/api/'],
                   cwd=root / 'frontend', check=True)
    return site


def observe(jar, manage, env, root, web_build=None):
    jar = Path(jar).resolve(strict=True)
    backend_port = 18000
    api = f'http://127.0.0.1:{backend_port}'
    proxy = 'http://127.0.0.1:8091'
    direct = build_opener(ProxyHandler({}))
    key = secrets.token_urlsafe(24)

    def zap(path, **params):
        with direct.open(f'{proxy}/{path}/?{urlencode({"apikey": key, **params})}', timeout=10) as reply:
            return json.load(reply)

    with ExitStack() as stack:
        temp = stack.enter_context(tempfile.TemporaryDirectory(prefix='farm-passive-'))
        site = prepare_web_build(root, api, web_build)
        web = stack.enter_context(ThreadingHTTPServer(('127.0.0.1', 0),
                                  partial(SimpleHTTPRequestHandler, directory=site)))
        Thread(target=web.serve_forever, daemon=True).start()
        stack.callback(web.shutdown)
        origin = f'http://localhost:{web.server_port}'
        server = subprocess.Popen(manage + ['runserver', f'127.0.0.1:{backend_port}', '--noreload'],
                                  env=dict(env, CORS_ALLOWED_ORIGINS=origin))
        stack.callback(stop, server)
        scanner = subprocess.Popen(['java', '-jar', str(jar), '-silent', '-daemon', '-host', '127.0.0.1',
                                    '-port', '8091', '-dir', temp, '-config', f'api.key={key}',
                                    '-config', 'autoupdate.checkOnStart=false'], stdout=subprocess.DEVNULL)
        stack.callback(stop, scanner)
        deadline = time.monotonic() + 120
        while True:
            if server.poll() is not None or scanner.poll() is not None:
                raise RuntimeError('Demo or proxy exited during startup. Check ports 18000 and 8091.')
            try:
                with direct.open(api + '/api/health/', timeout=2):
                    version = zap('JSON/core/view/version')['version']
                break
            except (URLError, TimeoutError):
                if time.monotonic() >= deadline:
                    raise
                time.sleep(1)
        zap('JSON/core/action/setMode', mode='safe')
        assert zap('JSON/core/view/mode')['mode'] == 'safe'
        scanners = zap('JSON/pscan/view/scanners')['scanners']
        enabled = [rule for rule in scanners if str(rule['enabled']).lower() == 'true']
        if not enabled:
            raise RuntimeError('No passive scanner rules enabled')

        with sync_playwright() as pw:
            browser = pw.chromium.launch(proxy={'server': proxy, 'bypass': 'localhost;<-loopback>'})
            page = browser.new_page()
            responses = set()
            def record_response(response):
                if response.url.startswith(api + '/api/'):
                    responses.add((response.request.method, urlsplit(response.url).path, response.status))
            page.on('response', record_response)
            # Keep the rehearsal local, including Flutter's rendering assets.
            def local_route(route):
                url = route.request.url
                if url.startswith(origin + '/') or url.startswith(api + '/'):
                    return route.continue_()
                return route.abort()
            page.route('**/*', local_route)
            page.goto(origin)
            page.locator('flt-semantics-placeholder').evaluate('(element) => element.click()')
            for label, value in [('Username', 'demo_owner'), ('Password', 'FieldbookDemo123!')]:
                field = page.get_by_role('textbox', name=label)
                field.click()
                expect(field).to_be_focused()
                # Flutter can replace the editing element as it gains focus.
                for attempt in range(3):
                    field.press('ControlOrMeta+a')
                    page.keyboard.insert_text(value)
                    try:
                        expect(field).to_have_value(value, timeout=1500)
                        break
                    except AssertionError:
                        if attempt == 2:
                            raise
                        field.click()
            with page.expect_response(lambda response: response.url == api + '/api/auth/login/'
                                      and response.request.method == 'POST') as login:
                page.get_by_role('button', name='Open my journal').click()
            if login.value.status != 200:
                raise RuntimeError(f'Demo sign-in returned HTTP {login.value.status}')
            page.get_by_role('button', name='All records').click()
            page.get_by_role('textbox').first.fill('Greenhouse drip irrigation')
            expect(page.get_by_text('Greenhouse drip irrigation', exact=False).or_(
                page.get_by_role('group', name='Greenhouse drip irrigation', exact=False)
            ).first).to_be_visible(timeout=10000)
            browser.close()

        site_nodes = set(zap('JSON/core/view/urls', baseurl=api)['urls'])
        observed = sorted({path for _, path, status in responses if status == 200 and api + path in site_nodes})
        required = {'/api/auth/login/', '/api/dashboard/', '/api/activities/'}
        if not required.issubset(observed):
            raise RuntimeError(f'Expected API routes missing from ZAP history: {required - set(observed)}')
        deadline = time.monotonic() + 90
        while int(zap('JSON/pscan/view/recordsToScan')['recordsToScan']) or zap('JSON/pscan/view/currentTasks')['currentTasks']:
            if time.monotonic() >= deadline:
                raise TimeoutError('Passive scan did not finish')
            time.sleep(.5)
        alerts = zap('JSON/core/view/alerts', baseurl=api + '/')['alerts']
        # Export findings without raw HTTP bodies, tokens or authentication headers.
        findings = {(a['pluginId'], a['alert'], a['risk'], a['confidence'], urlsplit(a['url']).path)
                    for a in alerts}
        report = dict(recorded_utc=datetime.now(timezone.utc).isoformat(), zap_version=version,
                      mode='safe', enabled_passive_rules=len(enabled), target=api,
                      workflow='Owner signed in, viewed dashboard, searched activity history for Greenhouse drip irrigation',
                      observed_api_paths=observed, alert_instances=len(alerts),
                      findings=[dict(zip(('rule', 'alert', 'risk', 'confidence', 'path'), row))
                                for row in sorted(findings)])
        path = root / 'docs/quality/evidence/zap-passive.json'
        path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        print(f'Wrote {path.name}: {len(observed)} API paths, {len(alerts)} alert instances.')
