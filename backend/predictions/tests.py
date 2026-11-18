from datetime import date
from io import BytesIO
from PIL import Image

from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import User
from crops.models import CropCycle, CropType
from farms.models import Farm, Field


class PredictionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='farmer',
            email='farmer@example.com',
            password='fixture-pass',
        )
        farm = Farm.objects.create(
            owner=self.user,
            name='Farm',
            location='Tunis',
            total_area=5,
        )
        field = Field.objects.create(
            farm=farm,
            name='Field',
            area=2,
            soil_type=Field.Soil.LOAM,
        )
        self.cycle = CropCycle.objects.create(
            field=field,
            crop_type=CropType.objects.get_or_create(name='Tomato')[0],
            planting_date=date(2026, 1, 1),
            area=1,
        )
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def test_disease_prediction_requires_image(self):
        self.assertEqual(
            self.client.post('/api/predictions/disease/', {}).status_code,
            400,
        )

    def test_pretrained_model_returns_a_confident_label_or_abstains(self):
        image = Image.new('RGB', (224, 224), color='green')
        buffer = BytesIO()
        image.save(buffer, format='JPEG')
        from .services import disease_prediction

        result = disease_prediction({}, buffer.getvalue())
        self.assertIn(result['source'], {'plantvillage-mobilenetv2'})
        self.assertIsInstance(result['prediction'], str)
        self.assertGreaterEqual(result['probability'], 0.0)
        self.assertLessEqual(result['probability'], 1.0)

    def test_yield_prediction_returns_estimate(self):
        estimate = self.client.post(
            '/api/predictions/yield/',
            {'cycle': self.cycle.pk},
            format='json',
        )
        self.assertEqual(estimate.status_code, 200)
        self.assertEqual(estimate.data['crop'], 'Tomato')
        self.assertTrue(
            self.client.get('/api/predictions/history/').data
        )
