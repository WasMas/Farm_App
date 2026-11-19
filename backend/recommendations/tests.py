from datetime import date

from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import User
from activities.models import Activity
from crops.models import CropType, CropCycle
from farms.models import Farm, Field, FieldAssignment


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

    def test_advanced_calendar_date_creates_irrigation_recommendation(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-20'},
            format='json',
        )
        self.assertEqual(response.status_code, 201)
        irrigation = [
            item for item in response.data if item['kind'] == 'irrigation'
        ]
        self.assertEqual(len(irrigation), 1)
        self.assertEqual(irrigation[0]['due_date'], '2026-01-07')

    def test_calendar_check_creates_next_irrigation_after_latest_due_date(self):
        first = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-20'},
            format='json',
        )
        self.assertEqual(first.status_code, 201)

        second = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-30'},
            format='json',
        )
        self.assertEqual(second.status_code, 201)
        irrigation = [
            item for item in second.data if item['kind'] == 'irrigation'
        ]
        self.assertEqual(len(irrigation), 1)
        self.assertEqual(irrigation[0]['due_date'], '2026-01-13')

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

    def test_accepting_irrigation_creates_day_work_activity(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-20'},
            format='json',
        )
        irrigation_id = next(
            item['id'] for item in response.data if item['kind'] == 'irrigation'
        )

        response = self.client.post(
            f'/api/recommendations/{irrigation_id}/accept/',
            {'as_of': '2026-01-20'},
            format='json',
        )

        self.assertEqual(response.status_code, 200)
        activity = Activity.objects.get(
            cycle=self.cycle,
            kind=Activity.Kind.IRRIGATION,
        )
        self.assertEqual(activity.date, date(2026, 1, 7))
        self.assertEqual(activity.quantity, 30)
        self.assertEqual(activity.unit, 'm3')

    def test_accepting_future_recommendation_is_rejected(self):
        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12'},
            format='json',
        )
        irrigation = next(
            item for item in response.data if item['kind'] == 'irrigation'
        )

        response = self.client.post(
            f"/api/recommendations/{irrigation['id']}/accept/",
            {'as_of': '2026-01-05'},
            format='json',
        )

        self.assertEqual(response.status_code, 400)

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

    def test_admin_role_sees_recommendations_for_other_farms(self):
        other_owner = User.objects.create_user(
            username='other-owner',
            email='other-owner@example.com',
            password='fixture-pass',
            role=User.Role.OWNER,
        )
        other_farm = Farm.objects.create(
            owner=other_owner,
            name='Other farm',
            location='Sousse',
            total_area=5,
        )
        other_field = Field.objects.create(
            farm=other_farm,
            name='Other field',
            area=1,
            soil_type=Field.Soil.LOAM,
        )
        other_cycle = CropCycle.objects.create(
            field=other_field,
            crop_type=self.crop_type,
            planting_date=date(2026, 1, 1),
            area=1,
            current_stage=CropCycle.Stage.VEGETATIVE,
        )
        admin = User.objects.create_user(
            username='role-admin',
            email='role-admin@example.com',
            password='fixture-pass',
            role=User.Role.ADMIN,
            is_staff=False,
        )
        self.client.force_authenticate(admin)

        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12', 'use_ai': False},
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        other_recommendations = [
            item for item in response.data if item['cycle'] == other_cycle.pk
        ]
        self.assertTrue(other_recommendations)

    def test_owner_generation_does_not_include_another_owner_farm(self):
        other_owner = User.objects.create_user(
            username='isolated-owner',
            email='isolated-owner@example.com',
            password='fixture-pass',
            role=User.Role.OWNER,
        )
        other_farm = Farm.objects.create(
            owner=other_owner,
            name='Isolated farm',
            location='Sfax',
            total_area=5,
        )
        other_field = Field.objects.create(
            farm=other_farm,
            name='Isolated field',
            area=1,
            soil_type=Field.Soil.LOAM,
        )
        other_cycle = CropCycle.objects.create(
            field=other_field,
            crop_type=self.crop_type,
            planting_date=date(2026, 1, 1),
            area=1,
            current_stage=CropCycle.Stage.VEGETATIVE,
        )

        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12', 'use_ai': False},
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        self.assertFalse(
            any(item['cycle'] == other_cycle.pk for item in response.data)
        )

    def test_worker_generation_only_includes_assigned_field(self):
        worker = User.objects.create_user(
            username='assigned-worker',
            email='assigned-worker@example.com',
            password='fixture-pass',
            role=User.Role.WORKER,
        )
        unassigned_field = Field.objects.create(
            farm=self.farm,
            name='Unassigned field',
            area=1,
            soil_type=Field.Soil.LOAM,
        )
        unassigned_cycle = CropCycle.objects.create(
            field=unassigned_field,
            crop_type=self.crop_type,
            planting_date=date(2026, 1, 1),
            area=1,
            current_stage=CropCycle.Stage.VEGETATIVE,
        )
        FieldAssignment.objects.create(
            field=self.field,
            worker=worker,
            assigned_by=self.owner,
        )
        self.client.force_authenticate(worker)

        response = self.client.post(
            '/api/recommendations/',
            {'as_of': '2026-01-12', 'use_ai': False},
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        cycles = {item['cycle'] for item in response.data}
        self.assertIn(self.cycle.pk, cycles)
        self.assertNotIn(unassigned_cycle.pk, cycles)

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
