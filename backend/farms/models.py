from decimal import Decimal
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models


class Farm(models.Model):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='owned_farms')
    name = models.CharField(max_length=120)
    location = models.CharField(max_length=200)
    total_area = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('.01'))])
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, validators=[MinValueValidator(-90), MaxValueValidator(90)])
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True, validators=[MinValueValidator(-180), MaxValueValidator(180)])
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name', 'id']
        constraints = [models.CheckConstraint(condition=models.Q(total_area__gt=0), name='farm_positive_area')]

    def __str__(self):
        return self.name


class FarmMembership(models.Model):
    class Role(models.TextChoices):
        MANAGER = 'manager', 'Manager'
        WORKER = 'worker', 'Worker'
        VIEWER = 'viewer', 'Viewer'

    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='memberships')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='farm_memberships')
    role = models.CharField(max_length=12, choices=Role, default=Role.WORKER)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['farm', 'user'], name='unique_farm_member')]


class Field(models.Model):
    class Soil(models.TextChoices):
        SANDY = 'sandy', 'Sandy'
        CLAY = 'clay', 'Clay'
        LOAM = 'loam', 'Loam'
        SILT = 'silt', 'Silt'
        OTHER = 'other', 'Other'

    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='fields')
    name = models.CharField(max_length=120)
    area = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('.01'))])
    soil_type = models.CharField(max_length=12, choices=Soil)

    class Meta:
        ordering = ['name', 'id']
        constraints = [models.UniqueConstraint(fields=['farm', 'name'], name='unique_field_name_in_farm'),
                       models.CheckConstraint(condition=models.Q(area__gt=0), name='field_positive_area')]

    def __str__(self):
        return f'{self.farm.name} / {self.name}'


class FieldAssignment(models.Model):
    field = models.ForeignKey(Field, on_delete=models.CASCADE, related_name='assignments')
    worker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='field_assignments')
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='created_field_assignments',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['field', 'worker'], name='unique_field_worker_assignment'),
        ]
