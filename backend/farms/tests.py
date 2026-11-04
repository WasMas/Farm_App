from django.test import TestCase
from rest_framework.test import APIClient
from accounts.models import User
from .models import Farm, Field, FarmMembership


class FarmTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user('owner', 'owner@test.com', 'fixture-pass')
        self.other = User.objects.create_user('other', 'other@test.com', 'fixture-pass')
        self.farm = Farm.objects.create(owner=self.owner, name='Olive farm', location='Tunis', total_area=10)
        self.client = APIClient()
        self.client.force_authenticate(self.owner)

    def test_isolation_and_relation_validation(self):
        self.assertEqual(self.client.get('/api/fields/?farm=invalid').status_code, 400)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get('/api/farms/').data['count'], 0)
        self.assertEqual(self.client.get(f'/api/farms/{self.farm.pk}/').status_code, 404)
        self.assertEqual(self.client.post('/api/fields/', {'farm': self.farm.pk, 'name': 'Hidden', 'area': 1, 'soil_type': 'loam'}).status_code, 400)

    def test_field_area_and_farm_area_validation(self):
        field = Field.objects.create(farm=self.farm, name='A', area=8, soil_type='loam')
        self.assertEqual(self.client.post('/api/fields/', {'farm': self.farm.pk, 'name': 'B', 'area': 3, 'soil_type': 'sandy'}).status_code, 400)
        self.assertEqual(self.client.patch(f'/api/farms/{self.farm.pk}/', {'total_area': 7}).status_code, 400)
        self.assertEqual(self.client.patch(f'/api/fields/{field.pk}/', {'area': 6}).status_code, 200)

    def test_shared_read_only_and_worker_permissions(self):
        FarmMembership.objects.create(farm=self.farm, user=self.other, role='viewer')
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get(f'/api/farms/{self.farm.pk}/').status_code, 200)
        self.assertEqual(self.client.patch(f'/api/farms/{self.farm.pk}/', {'name': 'Wrong'}).status_code, 403)
        self.assertEqual(self.client.post('/api/fields/', {'farm': self.farm.pk, 'name': 'B', 'area': 1, 'soil_type': 'clay'}).status_code, 400)
        FarmMembership.objects.filter(user=self.other).update(role='worker')
        self.assertEqual(self.client.post('/api/fields/', {'farm': self.farm.pk, 'name': 'B', 'area': 1, 'soil_type': 'clay'}).status_code, 201)
        self.assertEqual(self.client.post(f'/api/farms/{self.farm.pk}/members/', {'username': 'owner', 'role': 'manager'}).status_code, 403)

    def test_expert_cannot_write_even_with_worker_membership(self):
        expert = User.objects.create_user('expert', 'expert@test.com', 'fixture-pass', role='expert')
        FarmMembership.objects.create(farm=self.farm, user=expert, role='worker')
        self.client.force_authenticate(expert)
        self.assertEqual(self.client.get('/api/farms/').data['count'], 1)
        self.assertEqual(self.client.post('/api/farms/', {'name': 'Denied', 'location': 'Tunis', 'total_area': 3}).status_code, 403)
        self.assertEqual(self.client.post('/api/fields/', {'farm': self.farm.pk, 'name': 'Denied', 'area': 1, 'soil_type': 'clay'}).status_code, 400)
        self.farm.owner = expert
        self.farm.save()
        self.assertFalse(self.client.get(f'/api/farms/{self.farm.pk}/').data['can_share'])
        self.assertEqual(self.client.delete(f'/api/farms/{self.farm.pk}/').status_code, 403)
        self.assertEqual(self.client.post(f'/api/farms/{self.farm.pk}/members/', {'username': 'other', 'role': 'manager'}).status_code, 403)
