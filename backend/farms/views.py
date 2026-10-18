from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from accounts.models import User
from core.viewsets import SafeModelViewSet
from core.models import record_event
from .access import visible_farms, can_manage, require_work
from .models import FarmMembership, Field
from .serializers import FarmSerializer, FieldSerializer, MembershipSerializer


class FarmViewSet(SafeModelViewSet):
    serializer_class = FarmSerializer
    search_fields = ['name', 'location']

    def get_queryset(self):
        queryset = visible_farms(self.request.user).select_related('owner').prefetch_related('fields', 'memberships')
        if self.action in ['update', 'partial_update']:
            # Lock the farm before checking changes to its total area.
            return queryset.select_for_update(of=('self',))
        return queryset

    def perform_create(self, serializer):
        if self.request.user.role == 'expert' and not self.request.user.is_staff:
            raise PermissionDenied('Expert accounts have read-only farm access in this MVP.')
        instance = serializer.save(owner=self.request.user)
        record_event(self.request.user, instance, 'create')

    def perform_update(self, serializer):
        if not can_manage(self.request.user, serializer.instance):
            raise PermissionDenied('Only the owner or a manager may edit this farm.')
        super().perform_update(serializer)

    @transaction.atomic
    def update(self, *args, **kwargs):
        return super().update(*args, **kwargs)

    def perform_destroy(self, instance):
        if not (self.request.user.is_staff or instance.owner_id == self.request.user.pk):
            raise PermissionDenied('Only the owner may delete this farm.')
        super().perform_destroy(instance)

    @action(detail=True, methods=['get', 'post'])
    def members(self, request, pk=None):
        farm = self.get_object()
        if request.method == 'GET':
            return Response(MembershipSerializer(farm.memberships.select_related('user'), many=True).data)
        if not (request.user.is_staff or farm.owner_id == request.user.pk):
            raise PermissionDenied('Only the owner may manage farm access.')
        user = get_object_or_404(User, username=request.data.get('username'), is_active=True)
        if user.pk == farm.owner_id:
            raise ValidationError('The owner already has full access.')
        serializer = MembershipSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        membership, _ = FarmMembership.objects.update_or_create(farm=farm, user=user, defaults=serializer.validated_data)
        record_event(request.user, membership, 'share')
        return Response(MembershipSerializer(membership).data, status=201)

    @action(detail=True, methods=['delete'], url_path=r'members/(?P<user_id>[^/.]+)')
    def remove_member(self, request, user_id=None, pk=None):
        farm = self.get_object()
        if not (request.user.is_staff or farm.owner_id == request.user.pk):
            raise PermissionDenied('Only the owner may manage farm access.')
        membership = get_object_or_404(FarmMembership, farm=farm, user_id=user_id)
        record_event(request.user, membership, 'unshare')
        membership.delete()
        return Response(status=204)


class FieldViewSet(SafeModelViewSet):
    serializer_class = FieldSerializer
    search_fields = ['name', 'soil_type']

    def get_queryset(self):
        queryset = Field.objects.filter(farm__in=visible_farms(self.request.user)).select_related('farm')
        if self.request.query_params.get('farm'):
            queryset = queryset.filter(farm_id=self.request.query_params['farm'])
        return queryset

    @transaction.atomic
    def create(self, *args, **kwargs):
        return super().create(*args, **kwargs)

    @transaction.atomic
    def update(self, *args, **kwargs):
        return super().update(*args, **kwargs)

    def perform_destroy(self, instance):
        require_work(self.request.user, instance.farm)
        super().perform_destroy(instance)
