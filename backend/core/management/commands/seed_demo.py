from datetime import timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from accounts.models import User
from activities.models import Activity
from ai_chat.models import ChatConversation, ChatMessage
from core.models import AuditEvent
from crops.models import CropCycle, CropType
from farms.models import Farm, Field, FarmMembership, FieldAssignment
from weather.models import WeatherConfiguration, WeatherSnapshot


DEMO_PASSWORD = 'FieldbookDemo123!'


class Command(BaseCommand):
    help = 'Replace application demo data while preserving existing administrator accounts.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Delete existing non-admin users and application data before seeding.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if not options['reset']:
            raise CommandError('Run with --reset to replace the presentation data.')

        preserved_admin_ids = set(
            User.objects.filter(
                Q(role=User.Role.ADMIN) | Q(is_staff=True) | Q(is_superuser=True)
            ).values_list('id', flat=True)
        )

        # Delete in dependency order so protected farm/cycle references are not left behind.
        Activity.objects.all().delete()
        CropCycle.objects.all().delete()
        Field.objects.all().delete()
        Farm.objects.all().delete()
        ChatConversation.objects.all().delete()
        WeatherSnapshot.objects.all().delete()
        WeatherConfiguration.objects.all().delete()
        AuditEvent.objects.all().delete()
        FarmMembership.objects.all().delete()
        FieldAssignment.objects.all().delete()

        try:
            from predictions.models import PredictionRecord
            PredictionRecord.objects.all().delete()
        except ImportError:
            pass
        try:
            from recommendations.models import Recommendation
            Recommendation.objects.all().delete()
        except ImportError:
            pass

        User.objects.exclude(id__in=preserved_admin_ids).delete()

        admin_count = len(preserved_admin_ids)
        today = timezone.localdate()

        owner = self._create_user(
            'demo_owner',
            'owner@fieldbook.demo',
            'Amina',
            'Ben Salem',
            User.Role.OWNER,
            'Farm owner',
        )
        north_worker = self._create_user(
            'demo_north',
            'north@fieldbook.demo',
            'Sami',
            'Trabelsi',
            User.Role.WORKER,
            'North field worker',
        )
        south_worker = self._create_user(
            'demo_south',
            'south@fieldbook.demo',
            'Lina',
            'Jaziri',
            User.Role.WORKER,
            'South field worker',
        )
        expert = self._create_user(
            'demo_expert',
            'expert@fieldbook.demo',
            'Karim',
            'Mansour',
            User.Role.EXPERT,
            'Agricultural expert',
        )

        farm = Farm.objects.create(
            owner=owner,
            name='Green Valley Farm',
            location='Nabeul, Tunisia',
            total_area=Decimal('18.50'),
            latitude=Decimal('36.451000'),
            longitude=Decimal('10.735000'),
        )

        north = Field.objects.create(
            farm=farm,
            name='North Terrace',
            area=Decimal('5.50'),
            soil_type=Field.Soil.SANDY,
        )
        greenhouse = Field.objects.create(
            farm=farm,
            name='Greenhouse A',
            area=Decimal('2.00'),
            soil_type=Field.Soil.LOAM,
        )
        olive = Field.objects.create(
            farm=farm,
            name='Olive Grove',
            area=Decimal('6.50'),
            soil_type=Field.Soil.LOAM,
        )
        wheat = Field.objects.create(
            farm=farm,
            name='Western Plot',
            area=Decimal('4.50'),
            soil_type=Field.Soil.CLAY,
        )

        FieldAssignment.objects.create(
            field=north,
            worker=north_worker,
            assigned_by=owner,
        )
        FieldAssignment.objects.create(
            field=greenhouse,
            worker=north_worker,
            assigned_by=owner,
        )
        FieldAssignment.objects.create(
            field=olive,
            worker=south_worker,
            assigned_by=owner,
        )
        FieldAssignment.objects.create(
            field=wheat,
            worker=south_worker,
            assigned_by=owner,
        )
        FarmMembership.objects.create(
            farm=farm,
            user=north_worker,
            role=FarmMembership.Role.WORKER,
        )
        FarmMembership.objects.create(
            farm=farm,
            user=south_worker,
            role=FarmMembership.Role.WORKER,
        )
        FarmMembership.objects.create(
            farm=farm,
            user=expert,
            role=FarmMembership.Role.VIEWER,
        )

        tomato = self._upsert_crop(
            'Tomato',
            'Warm-season vegetable with regular irrigation needs.',
            ['sandy', 'loam'],
            {'flowering': 45, 'fruiting': 70, 'mature': 100, 'harvest': 110},
        )
        potato = self._upsert_crop(
            'Potato',
            'Tubers suited to loose, well-drained soil.',
            ['sandy', 'loam'],
            {'flowering': 50, 'mature': 90, 'harvest': 100},
        )
        olive_crop = self._upsert_crop(
            'Olive',
            'Long-lived Mediterranean orchard crop.',
            ['loam', 'sandy'],
            {'flowering': 180, 'mature': 240, 'harvest': 270},
        )
        wheat_crop = self._upsert_crop(
            'Wheat',
            'Cool-season cereal for fertile field plots.',
            ['loam', 'clay', 'silt'],
            {'flowering': 75, 'mature': 120, 'harvest': 140},
        )
        pepper = self._upsert_crop(
            'Pepper',
            'Greenhouse or warm-field vegetable.',
            ['loam', 'sandy'],
            {'flowering': 55, 'fruiting': 80, 'mature': 110, 'harvest': 120},
        )
        barley = self._upsert_crop(
            'Barley',
            'Adaptable cereal with moderate water needs.',
            ['loam', 'clay', 'silt'],
            {'flowering': 70, 'mature': 115, 'harvest': 130},
        )

        tomato_cycle = CropCycle.objects.create(
            field=north,
            crop_type=tomato,
            variety='Cherry tomato',
            planting_date=today - timedelta(days=58),
            area=Decimal('3.50'),
            current_stage=CropCycle.Stage.FLOWERING,
            status=CropCycle.Status.ACTIVE,
        )
        pepper_cycle = CropCycle.objects.create(
            field=greenhouse,
            crop_type=pepper,
            variety='Green bell pepper',
            planting_date=today - timedelta(days=64),
            area=Decimal('1.50'),
            current_stage=CropCycle.Stage.FRUITING,
            status=CropCycle.Status.ACTIVE,
        )
        olive_cycle = CropCycle.objects.create(
            field=olive,
            crop_type=olive_crop,
            variety='Chemlali',
            planting_date=today - timedelta(days=250),
            area=Decimal('6.50'),
            current_stage=CropCycle.Stage.MATURE,
            status=CropCycle.Status.ACTIVE,
        )
        wheat_cycle = CropCycle.objects.create(
            field=wheat,
            crop_type=wheat_crop,
            variety='Durum wheat',
            planting_date=today - timedelta(days=88),
            area=Decimal('4.00'),
            current_stage=CropCycle.Stage.FLOWERING,
            status=CropCycle.Status.ACTIVE,
        )
        potato_cycle = CropCycle.objects.create(
            field=north,
            crop_type=potato,
            variety='Spunta',
            planting_date=today - timedelta(days=30),
            area=Decimal('2.00'),
            current_stage=CropCycle.Stage.VEGETATIVE,
            status=CropCycle.Status.ACTIVE,
        )
        previous_tomato = CropCycle.objects.create(
            field=north,
            crop_type=tomato,
            variety='Roma',
            planting_date=today - timedelta(days=150),
            end_date=today - timedelta(days=30),
            area=Decimal('1.50'),
            current_stage=CropCycle.Stage.HARVEST,
            status=CropCycle.Status.COMPLETED,
        )

        self._seed_activities(
            owner,
            north_worker,
            south_worker,
            tomato_cycle,
            pepper_cycle,
            olive_cycle,
            wheat_cycle,
            potato_cycle,
            previous_tomato,
            today,
        )

        WeatherConfiguration.objects.create(
            user=owner,
            enabled=True,
            mode='public',
        )
        WeatherSnapshot.objects.create(
            user=owner,
            farm=farm,
            latitude=farm.latitude,
            longitude=farm.longitude,
            payload={
                'status': 'ok',
                'message': 'Demo weather snapshot',
                'current': {
                    'temperature': 26.4,
                    'humidity': 58,
                    'precipitation': 0,
                    'wind': 12,
                },
                'forecast': [
                    {'date': (today + timedelta(days=i)).isoformat(),
                     'high': 27 + i,
                     'low': 17 + i,
                     'rain': 0 if i < 3 else 2}
                    for i in range(5)
                ],
                'observed_at': timezone.now().isoformat(),
                'retrieved_at': timezone.now().isoformat(),
                'cached': True,
                'source': 'Demo',
            },
        )

        conversation = ChatConversation.objects.create(
            user=owner,
            title='Tomato flowering questions',
        )
        ChatMessage.objects.create(
            conversation=conversation,
            sender=ChatMessage.Sender.USER,
            content='My tomato leaves look pale. What should I check first?',
        )
        ChatMessage.objects.create(
            conversation=conversation,
            sender=ChatMessage.Sender.ASSISTANT,
            content='Check the soil moisture, recent fertilizer activity, and whether the pale color affects old or new leaves. The sandy North Terrace may need closer irrigation monitoring.',
        )

        try:
            from recommendations.models import Recommendation
            from recommendations.services import generate_recommendations
            recommendations = generate_recommendations(owner, today, use_ai=False)
            if not recommendations:
                Recommendation.objects.create(
                    cycle=tomato_cycle,
                    kind=Recommendation.Kind.STAGE,
                    title='Move tomato planting to fruit development',
                    message='The tomato planting has reached the flowering milestone. Confirm the change only after checking flower set.',
                    proposed_stage=CropCycle.Stage.FRUITING,
                    due_date=today - timedelta(days=1),
                    source='calendar',
                )
        except ImportError:
            pass

        try:
            from predictions.models import PredictionRecord
            PredictionRecord.objects.create(
                user=owner,
                cycle=tomato_cycle,
                kind=PredictionRecord.Kind.YIELD,
                result={
                    'cycle': tomato_cycle.pk,
                    'crop': 'Tomato',
                    'area': str(tomato_cycle.area),
                    'estimated_production_kg': {'low': 1400, 'high': 2100},
                    'expected_harvest_date': (today + timedelta(days=52)).isoformat(),
                    'source': 'baseline',
                    'disclaimer': 'Demonstration yield estimate, not a trained local model.',
                },
            )
            PredictionRecord.objects.create(
                user=owner,
                cycle=tomato_cycle,
                kind=PredictionRecord.Kind.DISEASE,
                result={
                    'prediction': 'Tomato - Early blight',
                    'probability': 0.91,
                    'top_label': 'Tomato - Early blight',
                    'actions': [
                        'Inspect affected leaves and lower stems',
                        'Remove severely damaged leaves',
                        'Confirm treatment with an agricultural expert',
                    ],
                    'source': 'plantvillage-mobilenetv2',
                    'model_id': 'LourivalGontijo/plantvillage-mobilenetv2',
                    'disclaimer': 'Demonstration result, not a diagnosis.',
                },
            )
        except ImportError:
            pass

        self.stdout.write(
            self.style.SUCCESS(
                f'Demo reset complete. Preserved {admin_count} administrator account(s).'
            )
        )
        self.stdout.write(
            'Login accounts: demo_owner, demo_north, demo_south, demo_expert'
        )
        self.stdout.write(f'Demo password: {DEMO_PASSWORD}')

    def _create_user(self, username, email, first_name, last_name, role, bio):
        return User.objects.create_user(
            username=username,
            email=email,
            first_name=first_name,
            last_name=last_name,
            password=DEMO_PASSWORD,
            role=role,
            bio=bio,
        )

    def _upsert_crop(self, name, description, soils, stages):
        crop, _ = CropType.objects.get_or_create(name=name)
        crop.description = description
        crop.suitable_soils = soils
        crop.stage_days = stages
        crop.save(update_fields=['description', 'suitable_soils', 'stage_days'])
        return crop

    def _seed_activities(
        self,
        owner,
        north_worker,
        south_worker,
        tomato,
        pepper,
        olive,
        wheat,
        potato,
        previous_tomato,
        today,
    ):
        activities = [
            (tomato, north_worker, 'irrigation', today - timedelta(days=2), 35, 'm3', '', 'Morning irrigation after dry soil check'),
            (tomato, north_worker, 'fertilization', today - timedelta(days=9), 18, 'kg', 'NPK 12-12-17', 'Flowering nutrient application'),
            (tomato, north_worker, 'observation', today - timedelta(days=4), None, '', '', 'Small pale spots observed on lower leaves'),
            (tomato, owner, 'treatment', today - timedelta(days=3), 2, 'l', 'Neem-based preventive', 'Leaf treatment after inspection'),
            (pepper, north_worker, 'irrigation', today - timedelta(days=1), 20, 'm3', '', 'Greenhouse drip irrigation'),
            (pepper, north_worker, 'observation', today - timedelta(days=5), None, '', '', 'Fruit set is even across rows'),
            (olive, south_worker, 'irrigation', today - timedelta(days=10), 90, 'm3', '', 'Deep irrigation before warm period'),
            (olive, owner, 'observation', today - timedelta(days=6), None, '', '', 'Canopy color healthy; inspect scale insects'),
            (wheat, south_worker, 'fertilization', today - timedelta(days=15), 120, 'kg', 'Nitrogen fertilizer', 'Vegetative growth support'),
            (wheat, south_worker, 'observation', today - timedelta(days=2), None, '', '', 'Uniform growth and no lodging'),
            (potato, north_worker, 'irrigation', today - timedelta(days=3), 30, 'm3', '', 'Light irrigation after planting bed check'),
            (potato, north_worker, 'observation', today - timedelta(days=1), None, '', '', 'Emergence uniform in the eastern rows'),
            (previous_tomato, north_worker, 'harvest', today - timedelta(days=32), 2200, 'kg', 'Roma tomatoes', 'Completed-season harvest'),
        ]
        for cycle, recorder, kind, date, quantity, unit, product, notes in activities:
            Activity.objects.create(
                cycle=cycle,
                recorded_by=recorder,
                kind=kind,
                date=date,
                quantity=quantity,
                unit=unit,
                product=product,
                notes=notes,
            )
