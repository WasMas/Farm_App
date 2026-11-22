from django.db import transaction
from core.models import record_event
from core.viewsets import SafeModelViewSet
from farms.access import visible_farms, require_work
from .models import Activity
from .serializers import ActivitySerializer, ActivityFilters


class ActivityViewSet(SafeModelViewSet):
    serializer_class = ActivitySerializer
    search_fields = ['notes', 'product', 'cycle__crop_type__name', 'cycle__field__name']

    def get_queryset(self):
        qs = Activity.objects.filter(cycle__field__farm__in=visible_farms(self.request.user)).select_related('cycle__field__farm', 'cycle__crop_type', 'recorded_by')
        filters = ActivityFilters(data=self.request.query_params)
        filters.is_valid(raise_exception=True)
        lookup = {'cycle': 'cycle_id', 'farm': 'cycle__field__farm_id', 'kind': 'kind', 'start': 'date__gte', 'end': 'date__lte'}
        return qs.filter(**{lookup[key]: value for key, value in filters.validated_data.items()})

    @transaction.atomic
    def perform_create(self, serializer):
        instance = serializer.save(recorded_by=self.request.user)
        record_event(self.request.user, instance, 'create')

    def perform_destroy(self, instance):
        require_work(self.request.user, instance.cycle.field.farm)
        super().perform_destroy(instance)
