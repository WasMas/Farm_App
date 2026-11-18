from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from accounts.models import User
from accounts.serializers import WorkerSerializer, UserSummarySerializer
from core.viewsets import SafeModelViewSet
from core.models import record_event
from core.query import positive_id
from .access import visible_farms, can_manage, require_work, can_work_field
from .models import FarmMembership, Field, FieldAssignment
from .serializers import (
    FarmSerializer,
    FieldSerializer,
    MembershipSerializer,
    FieldAssignmentSerializer,
)


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
        if not (self.request.user.is_staff or (self.request.user.role != 'expert' and instance.owner_id == self.request.user.pk)):
            raise PermissionDenied('Only the owner may delete this farm.')
        super().perform_destroy(instance)

    @action(detail=True, methods=['get', 'post'])
    def members(self, request, pk=None):
        farm = self.get_object()
        if request.method == 'GET':
            return Response(MembershipSerializer(farm.memberships.select_related('user'), many=True).data)
        if not (request.user.is_staff or (request.user.role != 'expert' and farm.owner_id == request.user.pk)):
            raise PermissionDenied('Only the owner may manage farm access.')
        user = get_object_or_404(User, username=request.data.get('username'), is_active=True)
        if user.pk == farm.owner_id:
            raise ValidationError('The owner already has full access.')
        serializer = MembershipSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        membership, _ = FarmMembership.objects.update_or_create(farm=farm, user=user, defaults=serializer.validated_data)
        record_event(request.user, membership, 'share')
        return Response(MembershipSerializer(membership).data, status=201)

    @action(detail=True, methods=['post'], url_path='workers')
    def create_worker(self, request, pk=None):
        farm = self.get_object()
        if not (request.user.is_staff or farm.owner_id == request.user.pk):
            raise PermissionDenied('Only the farm owner or an administrator may create workers.')
        serializer = WorkerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        worker = serializer.save()
        FarmMembership.objects.create(farm=farm, user=worker, role=FarmMembership.Role.WORKER)
        record_event(request.user, worker, 'create_worker')
        return Response(UserSummarySerializer(worker).data, status=201)

    @action(detail=True, methods=['post'], url_path='assignments')
    def assign_worker(self, request, pk=None):
        farm = self.get_object()
        if not (request.user.is_staff or farm.owner_id == request.user.pk):
            raise PermissionDenied('Only the farm owner or an administrator may assign workers.')
        field = get_object_or_404(Field, pk=request.data.get('field'), farm=farm)
        worker = get_object_or_404(User, pk=request.data.get('worker'), is_active=True)
        if not farm.memberships.filter(user=worker, role=FarmMembership.Role.WORKER).exists():
            raise ValidationError('The worker must belong to this farm first.')
        assignment, _ = FieldAssignment.objects.update_or_create(
            field=field,
            worker=worker,
            defaults={'assigned_by': request.user},
        )
        record_event(request.user, assignment, 'assign')
        return Response(FieldAssignmentSerializer(assignment).data, status=201)

    @action(detail=True, methods=['delete'], url_path=r'members/(?P<user_id>[^/.]+)')
    def remove_member(self, request, user_id=None, pk=None):
        farm = self.get_object()
        if not (request.user.is_staff or (request.user.role != 'expert' and farm.owner_id == request.user.pk)):
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
        if self.request.user.role == User.Role.WORKER:
            queryset = queryset.filter(assignments__worker=self.request.user)
        if self.request.query_params.get('farm'):
            queryset = queryset.filter(farm_id=positive_id(self.request.query_params['farm'], 'farm'))
        return queryset

    @transaction.atomic
    def create(self, *args, **kwargs):
        return super().create(*args, **kwargs)

    @transaction.atomic
    def update(self, *args, **kwargs):
        return super().update(*args, **kwargs)

    def perform_destroy(self, instance):
        if not can_manage(self.request.user, instance.farm):
            raise PermissionDenied('Only the farm owner or manager may delete fields.')
        super().perform_destroy(instance)
