from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from accounts.models import User
from activities.models import Activity
from crops.models import CropCycle, CropType
from farms.models import Farm, Field


class DashboardTests(TestCase):
    def test_summary_converts_units_and_isolates_users(self):
        owner = User.objects.create_user('owner', 'owner@summary.test', 'fixture-pass')
        other = User.objects.create_user('other', 'other@summary.test', 'fixture-pass')
        farm = Farm.objects.create(owner=owner, name='Grove', location='Tunis', total_area='4.5')
        field = Field.objects.create(farm=farm, name='A', area=2, soil_type='loam')
        today = timezone.localdate()
        cycle = CropCycle.objects.create(field=field, crop_type=CropType.objects.first(), planting_date=today - timedelta(days=20), area=2)
        for kind, quantity, unit, date in [('harvest', 2, 't', today), ('harvest', 50, 'kg', today), ('harvest', 30, 'items', today), ('irrigation', 1000, 'l', today), ('irrigation', 3, 'm3', today), ('irrigation', 50, 'm3', today - timedelta(days=8))]:
            Activity.objects.create(cycle=cycle, recorded_by=owner, kind=kind, quantity=quantity, unit=unit, date=date)
        client = APIClient()
        client.force_authenticate(owner)
        response = client.get('/api/dashboard/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['harvest_kg'], 2050)
        self.assertEqual(response.data['harvest_items'], 30)
        self.assertEqual(response.data['irrigation_m3_week'], 4)
        self.assertEqual(response.data['activities_week'], 5)
        client.force_authenticate(other)
        self.assertEqual(client.get('/api/dashboard/').data['farms'], 0)
        self.assertEqual(client.get('/api/dashboard/').data['recent_activities'], [])

    def test_selected_farm_limits_dashboard(self):
        owner = User.objects.create_user('dashboard-owner')
        a = Farm.objects.create(owner=owner, name='North', location='Tunis', total_area=4)
        Farm.objects.create(owner=owner, name='South', location='Tunis', total_area=8)
        client = APIClient()
        client.force_authenticate(owner)
        self.assertEqual(client.get('/api/dashboard/').data['farms'], 2)
        data = client.get('/api/dashboard/', {'farm': a.pk}).data
        self.assertEqual((data['farms'], data['total_area']), (1, 4))
