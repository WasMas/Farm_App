from django.db import transaction
from rest_framework.permissions import BasePermission, SAFE_METHODS
from core.viewsets import SafeModelViewSet
from farms.access import visible_farms, require_work
from .models import CropType, CropCycle
from .serializers import CropTypeSerializer, CropCycleSerializer


class ReferencePermission(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and (request.method in SAFE_METHODS or request.user.is_staff)


class CropTypeViewSet(SafeModelViewSet):
    queryset = CropType.objects.all()
    serializer_class = CropTypeSerializer
    permission_classes = [ReferencePermission]
    search_fields = ['name']


class CropCycleViewSet(SafeModelViewSet):
    serializer_class = CropCycleSerializer
    search_fields = ['crop_type__name', 'variety', 'field__name', 'field__farm__name']

    def get_queryset(self):
        qs = CropCycle.objects.filter(field__farm__in=visible_farms(self.request.user)).select_related('field__farm', 'crop_type')
        for key in ['field', 'status']:
            if self.request.query_params.get(key):
                qs = qs.filter(**{key: self.request.query_params[key]})
        return qs

    @transaction.atomic
    def create(self, *args, **kwargs):
        return super().create(*args, **kwargs)

    @transaction.atomic
    def update(self, *args, **kwargs):
        return super().update(*args, **kwargs)

    def perform_destroy(self, instance):
        require_work(self.request.user, instance.field.farm)
        super().perform_destroy(instance)
