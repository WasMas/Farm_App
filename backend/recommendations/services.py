from datetime import timedelta
import logging

from django.db import transaction
from django.conf import settings
from django.utils import timezone
from google import genai

from activities.models import Activity
from crops.models import CropCycle
from farms.access import visible_farms
from weather.models import WeatherConfiguration
from weather.services import weather_for
from .models import Recommendation


logger = logging.getLogger(__name__)


STAGES = [
    CropCycle.Stage.GERMINATION,
    CropCycle.Stage.VEGETATIVE,
    CropCycle.Stage.FLOWERING,
    CropCycle.Stage.FRUITING,
    CropCycle.Stage.MATURE,
    CropCycle.Stage.HARVEST,
]


def _next_stage(cycle):
    try:
        index = STAGES.index(cycle.current_stage)
    except ValueError:
        return None
    for stage in STAGES[index + 1:]:
        if isinstance(cycle.crop_type.stage_days.get(stage), int):
            return stage
    return None


def _context(cycle, as_of):
    recent = cycle.activities.order_by('-date')[:20]
    activities = [
        {
            'kind': activity.kind,
            'date': activity.date.isoformat(),
            'quantity': str(activity.quantity) if activity.quantity is not None else None,
            'unit': activity.unit,
            'product': activity.product,
        }
        for activity in recent
    ]
    weather = {'status': 'not_configured'}
    config = WeatherConfiguration.objects.filter(user=cycle.field.farm.owner).first()
    if config:
        weather = weather_for(cycle.field.farm, config)
    return {
        'as_of': as_of.isoformat(),
        'crop': cycle.crop_type.name,
        'variety': cycle.variety,
        'stage': cycle.get_current_stage_display(),
        'planting_date': cycle.planting_date.isoformat(),
        'field': cycle.field.name,
        'soil': cycle.field.get_soil_type_display(),
        'field_area_hectares': str(cycle.field.area),
        'planting_area_hectares': str(cycle.area),
        'suitable_soils': cycle.crop_type.suitable_soils,
        'recent_activities': activities,
        'weather': {
            'status': weather.get('status'),
            'current': weather.get('current'),
            'forecast': weather.get('forecast'),
        },
    }


def _ai_message(cycle, proposal, as_of):
    if not settings.GEMINI_API_KEY:
        return proposal['message'], 'calendar'
    try:
        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        interaction = client.interactions.create(
            model=settings.GEMINI_MODEL,
            input=(
                'Convert this structured, already-approved farming suggestion into '
                'a concise owner-facing recommendation. Do not invent quantities, '
                'dates, diseases, treatments, or weather readings. Do not claim the '
                'action is mandatory. Keep the weather and recent activity context '
                'in mind and use a calm, practical tone.\n'
                f'Context: {_context(cycle, as_of)}\n'
                f'Suggestion: {proposal}'
            ),
            generation_config={'temperature': 0.3, 'max_output_tokens': 240},
            store=False,
        )
        message = interaction.output_text
        if not message:
            raise RuntimeError('Gemini returned an empty recommendation.')
        return message.strip(), 'ai'
    except Exception:
        logger.warning(
            'Gemini recommendation wording failed; using the structured fallback.',
            exc_info=True,
        )
        return proposal['message'], 'calendar'
    finally:
        if 'client' in locals():
            client.close()


def _stage_recommendation(cycle, as_of):
    next_stage = _next_stage(cycle)
    if not next_stage:
        return None
    days = cycle.crop_type.stage_days[next_stage]
    due_date = cycle.planting_date + timedelta(days=days)
    if due_date > as_of:
        return None
    if Recommendation.objects.filter(
        cycle=cycle,
        kind=Recommendation.Kind.STAGE,
        due_date=due_date,
    ).exists():
        return None
    label = cycle.get_current_stage_display()
    next_label = cycle.Stage(next_stage).label
    return {
        'kind': Recommendation.Kind.STAGE,
        'title': f'{cycle.crop_type.name} may be ready for {next_label.lower()}',
        'message': (
            f'{cycle.crop_type.name} has been in {label.lower()} since '
            f'{cycle.planting_date:%d %b %Y}. The calendar suggests moving it '
            f'to {next_label.lower()}. Accept to update the planting record.'
        ),
        'proposed_stage': next_stage,
        'due_date': due_date,
    }


def _irrigation_recommendation(cycle, as_of):
    last = cycle.activities.filter(kind=Activity.Kind.IRRIGATION).order_by('-date').first()
    last_date = last.date if last else cycle.planting_date
    irrigation_interval = 3 if cycle.field.soil_type in {'sandy', 'silt'} else 6
    due_date = last_date + timedelta(days=irrigation_interval)
    if due_date > as_of:
        return None
    if Recommendation.objects.filter(
        cycle=cycle,
        kind=Recommendation.Kind.IRRIGATION,
        due_date=due_date,
    ).exists():
        return None
    return {
        'kind': Recommendation.Kind.IRRIGATION,
        'title': f'Check irrigation for {cycle.crop_type.name}',
        'message': (
            f'Irrigation is due after {irrigation_interval} days for '
            f'{cycle.field.get_soil_type_display().lower()} soil. '
            f'The last record was {last_date:%d %b %Y}. '
            'Review the soil and forecast, then accept to record the irrigation.'
        ),
        'activity_kind': Activity.Kind.IRRIGATION,
        'quantity': cycle.area * (40 if cycle.field.soil_type in {'sandy', 'silt'} else 30),
        'unit': 'm3',
        'due_date': due_date,
    }


def _fertilization_recommendation(cycle, as_of):
    last = cycle.activities.filter(
        kind=Activity.Kind.FERTILIZATION,
    ).order_by('-date').first()
    last_date = last.date if last else cycle.planting_date
    if cycle.current_stage not in {
        CropCycle.Stage.VEGETATIVE,
        CropCycle.Stage.FLOWERING,
        CropCycle.Stage.FRUITING,
    }:
        return None
    due_date = last_date + timedelta(days=21)
    if due_date > as_of:
        return None
    if Recommendation.objects.filter(
        cycle=cycle,
        kind=Recommendation.Kind.FERTILIZATION,
        due_date=due_date,
    ).exists():
        return None
    return {
        'kind': Recommendation.Kind.FERTILIZATION,
        'title': f'Review fertilization for {cycle.crop_type.name}',
        'message': (
            f'Fertilization has not been reviewed since {last_date:%d %b %Y}. '
            f'{cycle.crop_type.name} is in {cycle.get_current_stage_display().lower()}, '
            'so review crop needs and soil conditions before adding an approved product.'
        ),
        'activity_kind': Activity.Kind.OBSERVATION,
        'quantity': None,
        'unit': '',
        'due_date': due_date,
    }


@transaction.atomic
def generate_recommendations(user, as_of=None, use_ai=False):
    as_of = as_of or timezone.localdate()
    cycles = CropCycle.objects.filter(
        field__farm__in=visible_farms(user),
        status=CropCycle.Status.ACTIVE,
    ).select_related('crop_type', 'field__farm')
    created = []
    for cycle in cycles:
        for proposal in (
            _stage_recommendation(cycle, as_of),
            _irrigation_recommendation(cycle, as_of),
            _fertilization_recommendation(cycle, as_of),
        ):
            if proposal:
                if use_ai:
                    proposal['message'], proposal['source'] = _ai_message(
                        cycle,
                        proposal,
                        as_of,
                    )
                created.append(
                    Recommendation.objects.create(cycle=cycle, **proposal)
                )
    return created


@transaction.atomic
def decide_recommendation(recommendation, user, accepted):
    if recommendation.status != Recommendation.Status.PENDING:
        return recommendation
    recommendation.status = (
        Recommendation.Status.ACCEPTED if accepted else Recommendation.Status.REFUSED
    )
    recommendation.decided_by = user
    recommendation.decided_at = timezone.now()
    recommendation.save(update_fields=['status', 'decided_by', 'decided_at'])
    if accepted:
        if recommendation.proposed_stage:
            recommendation.cycle.current_stage = recommendation.proposed_stage
            recommendation.cycle.save(update_fields=['current_stage'])
        if recommendation.activity_kind:
            Activity.objects.create(
                cycle=recommendation.cycle,
                recorded_by=user,
                kind=recommendation.activity_kind,
                date=min(recommendation.due_date, timezone.localdate()),
                quantity=recommendation.quantity,
                unit=recommendation.unit,
                notes=f'Accepted recommendation: {recommendation.title}',
            )
    return recommendation
