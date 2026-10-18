import os
from io import StringIO
from unittest.mock import patch
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase
from rest_framework.test import APIClient
from .models import User


class AuthenticationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.payload = {'username': 'farmer', 'email': 'farmer@example.com', 'name': 'Farmer', 'password': 'A-test-passphrase-481!'}

    def test_registration_cannot_choose_admin_and_tokens_logout(self):
        response = self.client.post('/api/auth/register/', {**self.payload, 'role': 'admin', 'is_staff': True})
        self.assertEqual(response.status_code, 201)
        user = User.objects.get(username='farmer')
        self.assertEqual(user.role, 'farmer')
        self.assertFalse(user.is_staff)
        self.assertTrue(user.groups.filter(name='Farmer').exists())
        self.assertNotIn('password', response.data)
        login = self.client.post('/api/auth/login/', self.payload)
        self.assertEqual(login.status_code, 200)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {login.data["access"]}')
        self.assertEqual(self.client.get('/api/auth/me/').status_code, 200)
        self.assertEqual(self.client.post('/api/auth/logout/', {'refresh': login.data['refresh']}).status_code, 204)
        self.assertEqual(self.client.post('/api/auth/refresh/', {'refresh': login.data['refresh']}).status_code, 401)

    def test_weak_password_and_protected_endpoint(self):
        self.assertEqual(self.client.get('/api/auth/me/').status_code, 401)
        self.assertEqual(self.client.post('/api/auth/register/', {**self.payload, 'password': '123'}).status_code, 400)

    def test_role_and_admin_flags_stay_consistent(self):
        user = User.objects.create_user('roles', 'roles@test.com', 'fixture-pass', role='admin')
        self.assertTrue(user.is_staff)
        user.role = 'farmer'
        user.save()
        self.assertFalse(user.is_staff)
        self.assertFalse(user.groups.filter(name='Administrator').exists())

    @patch.dict(os.environ, {'INITIAL_ADMIN_USERNAME': 'rootfarm', 'INITIAL_ADMIN_EMAIL': 'root@example.com',
                             'INITIAL_ADMIN_PASSWORD': 'A-bootstrap-passphrase-802!'})
    def test_bootstrap_is_idempotent_and_does_not_reset_password(self):
        call_command('ensure_admin', stdout=StringIO())
        user = User.objects.get(username='rootfarm')
        original = user.password
        call_command('ensure_admin', stdout=StringIO())
        user.refresh_from_db()
        self.assertEqual(User.objects.filter(is_superuser=True).count(), 1)
        self.assertEqual(user.password, original)

    @patch.dict(os.environ, {'INITIAL_ADMIN_USERNAME': '', 'INITIAL_ADMIN_PASSWORD': ''})
    def test_bootstrap_requires_explicit_credentials(self):
        with self.assertRaises(CommandError):
            call_command('ensure_admin', stdout=StringIO())
