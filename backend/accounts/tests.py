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
        self.payload = {'username': 'owner', 'email': 'owner@example.com', 'name': 'Owner', 'password': 'A-test-passphrase-481!'}

    def test_registration_cannot_choose_admin_and_tokens_logout(self):
        response = self.client.post('/api/auth/register/', {**self.payload, 'role': 'admin', 'is_staff': True})
        self.assertIn(response.status_code, {404, 410})
        user = User.objects.create_user(
            username='owner',
            email='owner@example.com',
            first_name='Owner',
            password='A-test-passphrase-481!',
            role=User.Role.OWNER,
        )
        self.assertEqual(user.role, 'owner')
        self.assertFalse(user.is_staff)
        self.assertTrue(user.groups.filter(name='Farm owner').exists())
        login = self.client.post('/api/auth/login/', self.payload)
        self.assertEqual(login.status_code, 200)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {login.data["access"]}')
        self.assertEqual(self.client.get('/api/auth/me/').status_code, 200)
        self.assertEqual(self.client.post('/api/auth/logout/', {'refresh': login.data['refresh']}).status_code, 204)
        self.assertEqual(self.client.post('/api/auth/refresh/', {'refresh': login.data['refresh']}).status_code, 401)

    def test_weak_password_and_protected_endpoint(self):
        self.assertEqual(self.client.get('/api/auth/me/').status_code, 401)
        self.assertIn(
            self.client.post('/api/auth/register/', {**self.payload, 'password': '123'}).status_code,
            {404, 410},
        )

    def test_role_and_admin_flags_stay_consistent(self):
        user = User.objects.create_user('roles', 'roles@test.com', 'fixture-pass', role='admin')
        self.assertTrue(user.is_staff)
        user.role = 'owner'
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


class AdminDashboardTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_superuser(
            username='admin',
            email='admin@example.com',
            password='A-admin-passphrase-481!',
        )
        self.owner = User.objects.create_user(
            username='owner',
            email='owner@example.com',
            password='A-owner-passphrase-481!',
            role=User.Role.OWNER,
        )

    def test_only_admin_can_view_dashboard(self):
        self.client.force_authenticate(self.owner)
        self.assertEqual(
            self.client.get('/api/admin/dashboard/').status_code,
            403,
        )

        self.client.force_authenticate(self.admin)
        response = self.client.get('/api/admin/dashboard/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('counts', response.data)
        self.assertIn('users', response.data)

    def test_admin_can_change_user_role(self):
        self.client.force_authenticate(self.admin)
        response = self.client.patch(
            f'/api/admin/users/{self.owner.id}/',
            {'role': 'worker'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        self.owner.refresh_from_db()
        self.assertEqual(self.owner.role, User.Role.WORKER)

    def test_admin_owner_creation_creates_audit_event(self):
        self.client.force_authenticate(self.admin)
        response = self.client.post(
            '/api/admin/dashboard/',
            {
                'username': 'new-owner',
                'email': 'new-owner@example.com',
                'name': 'New Owner',
                'password': 'A-new-owner-passphrase-481!',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)

        audit = self.client.get('/api/admin/audit/')
        self.assertEqual(audit.status_code, 200)
        self.assertTrue(
            any(
                event['action'] == 'create_owner'
                and event['actor'] == self.admin.username
                for event in audit.data
            )
        )

    def test_admin_audit_filters_by_action_actor_and_entity(self):
        from core.models import AuditEvent

        AuditEvent.objects.create(
            actor=self.admin,
            action='create_owner',
            entity='accounts.User',
            object_id=123,
        )
        self.client.force_authenticate(self.admin)
        response = self.client.get(
            '/api/admin/audit/',
            {'action': 'create', 'actor': 'admin', 'entity': 'accounts'},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertIn('summary', response.data[0])
