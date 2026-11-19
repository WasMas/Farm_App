from django.conf import settings
from django.db import models
from crops.models import CropCycle


class Recommendation(models.Model):
    class Kind(models.TextChoices):
        STAGE = 'stage', 'Growth stage'
        IRRIGATION = 'irrigation', 'Irrigation'
        FERTILIZATION = 'fertilization', 'Fertilization'

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACCEPTED = 'accepted', 'Accepted'
        REFUSED = 'refused', 'Refused'

    cycle = models.ForeignKey(CropCycle, on_delete=models.CASCADE, related_name='recommendations')
    kind = models.CharField(max_length=20, choices=Kind)
    title = models.CharField(max_length=180)
    message = models.TextField()
    proposed_stage = models.CharField(max_length=20, blank=True)
    activity_kind = models.CharField(max_length=20, blank=True)
    quantity = models.DecimalField(max_digits=12, decimal_places=3, null=True, blank=True)
    unit = models.CharField(max_length=8, blank=True)
    due_date = models.DateField()
    source = models.CharField(max_length=20, default='calendar')
    status = models.CharField(max_length=10, choices=Status, default=Status.PENDING)
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='decided_recommendations',
    )
    decided_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['status', 'due_date', '-created_at']
        constraints = [
            models.UniqueConstraint(
                fields=['cycle', 'kind', 'due_date'],
                name='unique_recommendation_per_cycle_kind_date',
            ),
        ]
