from django.conf import settings
from django.db import models


class AuditEvent(models.Model):
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL)
    action = models.CharField(max_length=32)
    entity = models.CharField(max_length=80)
    object_id = models.PositiveBigIntegerField()
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-recorded_at']


def record_event(actor, instance, action):
    AuditEvent.objects.create(actor=actor, action=action, entity=instance._meta.label, object_id=instance.pk)
