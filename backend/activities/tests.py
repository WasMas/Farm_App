from datetime import timedelta
from django.utils import timezone
from django.test import TestCase
from rest_framework.test import APIClient
from accounts.models import User
from farms.models import Farm, Field, FarmMembership
from crops.models import CropType, CropCycle
from core.models import AuditEvent


class ActivityTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user('owner', 'owner@test.com', 'fixture-pass')
        self.other = User.objects.create_user('other', 'other@test.com', 'fixture-pass')
        self.farm = Farm.objects.create(owner=self.owner, name='Farm', location='Tunis', total_area=3)
        field = Field.objects.create(farm=self.farm, name='North', area=2, soil_type='loam')
        self.today = timezone.localdate()
        self.cycle = CropCycle.objects.create(field=field, crop_type=CropType.objects.first(), area=2, planting_date=self.today - timedelta(days=10))
        self.payload = {'cycle': self.cycle.pk, 'kind': 'irrigation', 'date': str(self.today), 'quantity': '12.5', 'unit': 'm3'}
        self.client = APIClient()
        self.client.force_authenticate(self.owner)

    def test_units_dates_and_observations(self):
        self.assertEqual(self.client.post('/api/activities/', {**self.payload, 'unit': 'kg'}).status_code, 400)
        self.assertEqual(self.client.post('/api/activities/', {**self.payload, 'date': str(self.today - timedelta(days=11))}).status_code, 400)
        response = self.client.post('/api/activities/', self.payload)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['recorded_by'], self.owner.pk)
        self.assertTrue(AuditEvent.objects.filter(entity='activities.Activity', action='create').exists())
        self.assertEqual(self.client.post('/api/activities/', {'cycle': self.cycle.pk, 'kind': 'observation', 'date': str(self.today), 'notes': 'Leaves are healthy.'}).status_code, 201)
        self.assertEqual(self.client.delete(f'/api/crop-cycles/{self.cycle.pk}/').status_code, 409)

    def test_isolation_and_read_only_membership(self):
        activity = self.client.post('/api/activities/', self.payload).data
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get('/api/activities/').data['count'], 0)
        self.assertEqual(self.client.patch(f'/api/activities/{activity["id"]}/', {'quantity': '1'}).status_code, 404)
        FarmMembership.objects.create(farm=self.farm, user=self.other, role='viewer')
        self.assertEqual(self.client.get('/api/activities/').data['count'], 1)
        self.assertEqual(self.client.post('/api/activities/', self.payload).status_code, 400)

    def test_failed_audit_rolls_back_activity_and_retry_succeeds(self):
        from unittest.mock import patch
        from .models import Activity

        with patch('activities.views.record_event', side_effect=RuntimeError('Audit unavailable')):
            with self.assertRaisesMessage(RuntimeError, 'Audit unavailable'):
                self.client.post('/api/activities/', self.payload)
        self.assertFalse(Activity.objects.exists())
        response = self.client.post('/api/activities/', self.payload)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Activity.objects.count(), 1)
        event = AuditEvent.objects.get(entity='activities.Activity', action='create')
        self.assertEqual((event.actor_id, event.object_id), (self.owner.pk, response.data['id']))
        self.assertIsNotNone(event.recorded_at)
