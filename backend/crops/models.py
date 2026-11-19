from decimal import Decimal
from django.core.validators import MinValueValidator
from django.db import models
from farms.models import Field


class CropType(models.Model):
    name = models.CharField(max_length=80, unique=True)
    description = models.TextField(blank=True)
    suitable_soils = models.JSONField(default=list, blank=True)
    stage_days = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['name', 'id']

    def __str__(self):
        return self.name


class CropCycle(models.Model):
    class Stage(models.TextChoices):
        GERMINATION = 'germination', 'Germination'
        VEGETATIVE = 'vegetative', 'Vegetative growth'
        FLOWERING = 'flowering', 'Flowering'
        FRUITING = 'fruiting', 'Fruit development'
        MATURE = 'mature', 'Mature'
        HARVEST = 'harvest', 'Harvest'

    class Status(models.TextChoices):
        ACTIVE = 'active', 'Active'
        COMPLETED = 'completed', 'Completed'

    field = models.ForeignKey(Field, on_delete=models.PROTECT, related_name='cycles')
    crop_type = models.ForeignKey(CropType, on_delete=models.PROTECT, related_name='cycles')
    variety = models.CharField(max_length=100, blank=True)
    planting_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    area = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('.01'))])
    current_stage = models.CharField(max_length=20, choices=Stage, default=Stage.GERMINATION)
    status = models.CharField(max_length=12, choices=Status, default=Status.ACTIVE)

    class Meta:
        ordering = ['-planting_date', '-id']
        constraints = [models.CheckConstraint(condition=models.Q(area__gt=0), name='cycle_positive_area')]

    def __str__(self):
        return f'{self.crop_type} / {self.field.name} / {self.planting_date}'
