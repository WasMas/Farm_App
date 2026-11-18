from django.db.models import Q
from rest_framework.exceptions import PermissionDenied
from .models import Farm, Field


def visible_farms(user):
    if user.is_staff:
        return Farm.objects.all()
    return Farm.objects.filter(Q(owner=user) | Q(pk__in=user.farm_memberships.values('farm_id')))


def can_manage(user, farm):
    return user.is_staff or (
        user.role not in {'expert', 'worker'}
        and (farm.owner_id == user.pk or farm.memberships.filter(user=user, role='manager').exists())
    )


def can_work(user, farm):
    return can_manage(user, farm) or (
        user.role not in {'expert', 'worker'}
        and farm.memberships.filter(user=user, role='worker').exists()
    ) or (
        user.role == 'worker'
        and farm.memberships.filter(user=user, role='worker').exists()
    )


def can_work_field(user, field: Field):
    if can_manage(user, field.farm):
        return True
    return (
        user.role == 'worker'
        and field.assignments.filter(worker=user).exists()
    )


def require_work(user, farm):
    if not can_work(user, farm):
        raise PermissionDenied('You have read-only access to this farm.')
