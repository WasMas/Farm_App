from datetime import timedelta
from decimal import Decimal
from django.db.models import Sum, Case, When, F, Value, DecimalField
from django.utils import timezone
from farms.models import Field
from crops.models import CropCycle
from activities.models import Activity


def converted_sum(queryset, conversions):
    expression = Case(*[When(unit=unit, then=F('quantity') * Value(factor)) for unit, factor in conversions.items()],
                      default=Value(0), output_field=DecimalField(max_digits=20, decimal_places=3))
    return queryset.aggregate(total=Sum(expression))['total'] or Decimal(0)


def summarize(farms):
    fields = Field.objects.filter(farm__in=farms)
    cycles = CropCycle.objects.filter(field__in=fields)
    activities = Activity.objects.filter(cycle__in=cycles)
    week = activities.filter(date__gte=timezone.localdate() - timedelta(days=6))
    harvests = activities.filter(kind='harvest')
    return {
        'farms': farms.count(), 'fields': fields.count(), 'active_cycles': cycles.filter(status='active').count(),
        'total_area': farms.aggregate(total=Sum('total_area'))['total'] or Decimal(0),
        'activities_week': week.count(),
        'irrigation_m3_week': converted_sum(week.filter(kind='irrigation'), {'m3': 1, 'l': Decimal('.001')}),
        'harvest_kg': converted_sum(harvests, {'kg': 1, 't': 1000}),
        'harvest_items': converted_sum(harvests, {'items': 1}),
    }
