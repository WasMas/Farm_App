from django.test import TestCase
from rest_framework.test import APIClient

class HealthTests(TestCase):
    def test_postgresql_health(self):
        response = APIClient().get('/api/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['database'], 'postgresql')
