import json
from unittest.mock import patch
from urllib.error import URLError
from django.test import TestCase
from rest_framework.test import APIClient
from accounts.models import User
from farms.models import Farm
from .models import WeatherConfiguration


class WeatherTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user('weatheruser', 'weather@test.com', 'fixture-pass')
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.farm = Farm.objects.create(owner=self.user, name='Farm', location='Tunis', total_area=3, latitude=36.8, longitude=10.18)
        self.url = f'/api/weather/?farm={self.farm.pk}'

    def test_unconfigured_and_key_is_never_returned(self):
        self.assertEqual(self.client.get(self.url).data['current']['temperature'], None)
        response = self.client.patch('/api/weather/config/', {'enabled': True, 'mode': 'customer', 'api_key': 'fixture-customer-key'})
        self.assertNotIn('fixture-customer-key', response.content.decode())
        config = WeatherConfiguration.objects.get(user=self.user)
        self.assertNotEqual(config.encrypted_key, 'fixture-customer-key')
        self.assertTrue(response.data['has_key'])
        self.client.patch('/api/weather/config/', {'clear_key': True})
        self.assertEqual(self.client.get(self.url).data['status'], 'not_configured')

    @patch('weather.services.urlopen')
    def test_success_cache_partial_values_and_failure_placeholders(self, fetch):
        self.client.patch('/api/weather/config/', {'enabled': True})
        fetch.return_value.__enter__.return_value.read.return_value = json.dumps({'current': {'temperature_2m': 0, 'relative_humidity_2m': 50, 'time': '2026-10-18T12:00'}, 'utc_offset_seconds': 3600}).encode()
        response = self.client.get(self.url)
        self.assertEqual(response.data['status'], 'ok')
        self.assertEqual(response.data['current']['temperature'], 0)
        self.assertIsNone(response.data['current']['wind'])
        self.assertTrue(self.client.get(self.url).data['cached'])
        fetch.side_effect = URLError('timeout')
        response = self.client.get(self.url + '&refresh=true')
        self.assertEqual(response.data['status'], 'unavailable')
        self.assertTrue(all(v is None for v in response.data['current'].values()))

    def test_weather_is_scoped_to_visible_farms(self):
        other = User.objects.create_user('otherweather', 'otherweather@test.com', 'fixture-pass')
        self.client.force_authenticate(other)
        self.assertEqual(self.client.get(self.url).status_code, 404)
