from django.db.models.deletion import ProtectedError
from rest_framework import status, viewsets
from rest_framework.exceptions import APIException
from django.db import transaction
from .models import record_event


class Conflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = 'This record has linked history. Keep it to preserve the farm journal.'


class SafeModelViewSet(viewsets.ModelViewSet):
    @transaction.atomic
    def perform_create(self, serializer):
        instance = serializer.save()
        record_event(self.request.user, instance, 'create')

    @transaction.atomic
    def perform_update(self, serializer):
        instance = serializer.save()
        record_event(self.request.user, instance, 'update')

    @transaction.atomic
    def perform_destroy(self, instance):
        try:
            record_event(self.request.user, instance, 'delete')
            instance.delete()
        except ProtectedError as exc:
            raise Conflict() from exc
