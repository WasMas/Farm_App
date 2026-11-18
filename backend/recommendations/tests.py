from datetime import date

from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import User
from crops.models import CropType, CropCycle
from farms.models import Farm, Field


class RecommendationTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user(
            username='owner',
            email='owner@example.com',
            password='fixture-pass',
            role=User.Role.OWNER,
        )
        self.farm = Farm.objects.create(
            owner=self.owner,
            name='Demo farm',
            location='Tunis',
            total_area=10,
        )
        self.field = Field.objects.create(
            farm=self.farm,
            name='North field',
            area=2,
            soil_type=Field.Soil.CLAY,
        )
        self.crop_type = CropType.objects.create(
            name='Demo tomato',
            suitable_soils=['loam'],
            stage_days={'flowering': 10},
        )
        self.cycle = CropCycle.objects.create(
            field=self.field,
            crop_type=self.crop_type,
            planting_date=date(2026, 1, 1),
            area=1,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.owner)

    def test_calendar_check_creates_pending_recommendation(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12'},
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        stage = next(item for item in response.data if item['kind'] == 'stage')
        self.assertEqual(stage['status'], 'pending')
        self.assertEqual(stage['proposed_stage'], 'flowering')

    def test_accepting_recommendation_updates_cycle(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12'},
            format='json',
        )
        recommendation_id = next(
            item['id'] for item in response.data if item['kind'] == 'stage'
        )
        response = self.client.post(
            f'/api/recommendations/{recommendation_id}/accept/',
        )
        self.assertEqual(response.status_code, 200)
        self.cycle.refresh_from_db()
        self.assertEqual(self.cycle.current_stage, CropCycle.Stage.FLOWERING)

    def test_refusing_recommendation_does_not_change_cycle(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12'},
            format='json',
        )
        recommendation_id = next(
            item['id'] for item in response.data if item['kind'] == 'stage'
        )
        response = self.client.post(
            f'/api/recommendations/{recommendation_id}/refuse/',
        )
        self.assertEqual(response.status_code, 200)
        self.cycle.refresh_from_db()
        self.assertEqual(self.cycle.current_stage, CropCycle.Stage.GERMINATION)

    def test_soil_mismatch_is_a_warning_not_a_block(self):
        response = self.client.post(
            '/api/crop-cycles/',
            {
                'field': self.field.pk,
                'crop_type': self.crop_type.pk,
                'planting_date': '2026-01-02',
                'area': 1,
                'current_stage': CropCycle.Stage.GERMINATION,
                'status': CropCycle.Status.ACTIVE,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        self.assertFalse(response.data['soil_compatible'])
        self.assertTrue(response.data['soil_warning'])
