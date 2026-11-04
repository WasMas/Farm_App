from decimal import Decimal
from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models
from crops.models import CropCycle


class Activity(models.Model):
    class Kind(models.TextChoices):
        IRRIGATION = 'irrigation', 'Irrigation'
        FERTILIZATION = 'fertilization', 'Fertilization'
        TREATMENT = 'treatment', 'Treatment'
        OBSERVATION = 'observation', 'Observation'
        HARVEST = 'harvest', 'Harvest'

    cycle = models.ForeignKey(CropCycle, on_delete=models.PROTECT, related_name='activities')
    recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    kind = models.CharField(max_length=20, choices=Kind)
    date = models.DateField()
    quantity = models.DecimalField(max_digits=12, decimal_places=3, null=True, blank=True, validators=[MinValueValidator(Decimal('.001'))])
    unit = models.CharField(max_length=8, blank=True)
    product = models.CharField(max_length=120, blank=True)
    notes = models.TextField(blank=True, max_length=2000)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date', '-created_at', '-id']
        indexes = [models.Index(fields=['cycle', '-date'])]
        constraints = [models.CheckConstraint(condition=models.Q(quantity__isnull=True) | models.Q(quantity__gt=0), name='activity_positive_quantity')]
