"""Two independent API requests compete for a single hectare in PostgreSQL."""
from concurrent.futures import ThreadPoolExecutor
from queue import Queue
from threading import Barrier, Event
from time import monotonic, sleep

from django.db import connection, connections
from django.test import tag, TransactionTestCase
from django.utils.timezone import localdate
from rest_framework.test import APIClient

from accounts.models import User
from crops.models import CropCycle, CropType
from farms.models import Farm, FarmMembership, Field


@tag("reliability")
class PlantingRaceTests(TransactionTestCase):
    def test_last_hectare(self):
        alice = User.objects.create_user('alice', 'alice@example.invalid')
        bob = User.objects.create_user('bob', 'bob@example.invalid')
        farm = Farm.objects.create(owner=alice, name='Grove', total_area=1)
        FarmMembership.objects.create(user=bob, farm=farm, role='manager')
        field = Field.objects.create(farm=farm, name='North', soil_type='loam', area=1)
        crop, _ = CropType.objects.get_or_create(name='Tomato')
        payload = {'field': field.pk, 'crop_type': crop.pk, 'area': 1,
                   'planting_date': str(localdate())}

        start = Barrier(2, timeout=15)
        release = Event()
        sessions = Queue()

        def submit(user):
            # Hold the winning transaction open until the observer sees the wait.
            def observe_field_lock(execute, sql, params, many, context):
                if 'FOR UPDATE' in sql and Field._meta.db_table in sql:
                    start.wait()
                    result = execute(sql, params, many, context)
                    if not release.wait(20):
                        raise TimeoutError('Observer did not release the field lock')
                    return result
                return execute(sql, params, many, context)

            try:
                with connection.cursor() as cursor:
                    cursor.execute('SELECT pg_backend_pid()')
                    sessions.put(cursor.fetchone()[0])
                client = APIClient()
                client.force_authenticate(user)
                with connection.execute_wrapper(observe_field_lock):
                    response = client.post('/api/crop-cycles/', payload)
                return user.username, response
            finally:
                connections.close_all()

        with ThreadPoolExecutor(max_workers=2) as pool:
            requests = [pool.submit(submit, user) for user in (alice, bob)]
            try:
                first, second = (sessions.get(timeout=15) for _ in range(2))
                deadline = monotonic() + 10
                with connection.cursor() as cursor:
                    while True:
                        cursor.execute('SELECT pg_blocking_pids(%s), pg_blocking_pids(%s)',
                                       [first, second])
                        blockers_a, blockers_b = cursor.fetchone()
                        if second in blockers_a or first in blockers_b:
                            print('PostgreSQL confirmed one planting request blocked the other.')
                            break
                        if monotonic() >= deadline:
                            self.fail('No lock wait observed between the two requests')
                        sleep(.02)
            finally:
                release.set()
            results = [request.result(timeout=20) for request in requests]

        self.assertCountEqual([response.status_code for _, response in results], [201, 400])
        for name, response in results:
            if response.status_code == 400:
                self.assertIn('Active planting areas cannot exceed the field area.', response.data['area'])
            print(f'{name}: HTTP {response.status_code}')
        saved = CropCycle.objects.get(field=field)
        self.assertEqual(saved.area, field.area)
        print('Database verified: one planting saved, one hectare allocated.')
