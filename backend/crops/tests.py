from datetime import date, timedelta
from django.test import TestCase
from rest_framework.test import APIClient
from accounts.models import User
from farms.models import Farm, Field
from .models import CropType


class CropTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user('cropowner', 'cropowner@test.com', 'fixture-pass')
        farm = Farm.objects.create(owner=self.user, name='Farm', location='Tunis', total_area=4)
        self.field = Field.objects.create(farm=farm, name='A', area=3, soil_type='loam')
        self.type, _ = CropType.objects.get_or_create(name='Tomato')
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.payload = {'field': self.field.pk, 'crop_type': self.type.pk, 'area': 2, 'planting_date': str(date.today() - timedelta(days=10))}

    def test_cycle_lifecycle_and_area(self):
        cycle = self.client.post('/api/crop-cycles/', self.payload)
        self.assertEqual(cycle.status_code, 201)
        self.assertEqual(self.client.post('/api/crop-cycles/', self.payload).status_code, 400)
        self.assertEqual(self.client.patch(f'/api/fields/{self.field.pk}/', {'area': 1}).status_code, 400)
        self.assertEqual(self.client.delete(f'/api/fields/{self.field.pk}/').status_code, 409)
        self.assertEqual(self.client.patch(f'/api/crop-cycles/{cycle.data["id"]}/', {'status': 'completed', 'end_date': str(date.today())}).status_code, 200)
        self.assertEqual(self.client.post('/api/crop-cycles/', self.payload).status_code, 201)

    def test_crop_reference_is_admin_only_and_invalid_dates(self):
        self.assertEqual(self.client.get('/api/crop-cycles/?field=invalid').status_code, 400)
        self.assertEqual(self.client.post('/api/crop-types/', {'name': 'Unauthorized'}).status_code, 403)
        self.assertEqual(self.client.post('/api/crop-cycles/', {**self.payload, 'planting_date': str(date.today() + timedelta(days=1))}).status_code, 400)

    def test_admin_can_manage_reference_data(self):
        admin = User.objects.create_user('catalogadmin', 'admin@catalogue.test', 'fixture-pass', role='admin')
        self.client.force_authenticate(admin)
        response = self.client.post('/api/crop-types/', {'name': 'Apricot', 'description': 'Reference crop'})
        self.assertEqual(response.status_code, 201)
        url = f'/api/crop-types/{response.data["id"]}/'
        self.assertEqual(self.client.patch(url, {'description': 'Updated'}).status_code, 200)
        self.assertEqual(self.client.delete(url).status_code, 204)
