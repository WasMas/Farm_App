from django.conf import settings
from django.db import models
from crops.models import CropCycle


class PredictionRecord(models.Model):
    class Kind(models.TextChoices):
        DISEASE = 'disease', 'Disease'
        YIELD = 'yield', 'Yield'

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='prediction_records',
    )
    cycle = models.ForeignKey(
        CropCycle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='prediction_records',
    )
    kind = models.CharField(max_length=12, choices=Kind)
    result = models.JSONField()
    image = models.ImageField(
        upload_to='prediction_images/%Y/%m/',
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
