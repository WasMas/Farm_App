from django.test import SimpleTestCase, TestCase
from rest_framework.exceptions import ValidationError
from .query import positive_id
from rest_framework.test import APIClient

class HealthTests(TestCase):
    def test_postgresql_health(self):
        response = APIClient().get('/api/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['database'], 'postgresql')



class FilterUnitTests(SimpleTestCase):
    def test_filter_identifier_must_be_positive(self):
        self.assertEqual(positive_id('42', 'farm'), 42)
        for value in ('0', '-2', 'North', None):
            with self.subTest(value=value), self.assertRaises(ValidationError):
                positive_id(value, 'farm')

class JournalCrudTests(TestCase):
    def test_four_entity_crud(self):
        from django.utils.timezone import localdate
        from accounts.models import User
        from crops.models import CropType

        owner = User.objects.create_user('crud-owner')
        client = APIClient()
        client.force_authenticate(owner)
        urls = []

        def exercise(collection, payload, changes):
            created = client.post('/api/' + collection + '/', payload)
            self.assertEqual(created.status_code, 201, created.data)
            pk = created.data['id']
            url = f'/api/{collection}/{pk}/'
            urls.append(url)
            self.assertEqual(client.get(url).data['id'], pk)
            updated = client.patch(url, changes)
            self.assertEqual(updated.status_code, 200, updated.data)
            saved = client.get(url).data
            for key, value in changes.items():
                self.assertEqual(saved[key], value)
            return pk

        farm = exercise('farms', {'name': 'North', 'location': 'Tunis', 'total_area': 8}, {'name': 'Grove'})
        field = exercise('fields', {'farm': farm, 'name': 'A', 'area': 4, 'soil_type': 'loam'}, {'name': 'B'})
        cycle = exercise('crop-cycles', {'field': field, 'crop_type': CropType.objects.first().pk,
                          'planting_date': localdate(), 'area': 1}, {'area': '2.00'})
        exercise('activities', {'cycle': cycle, 'date': localdate(), 'kind': 'observation',
                                'notes': 'First leaves'}, {'notes': 'Second leaves'})
        for url in reversed(urls):
            self.assertEqual(client.delete(url).status_code, 204)
            self.assertEqual(client.get(url).status_code, 404)

