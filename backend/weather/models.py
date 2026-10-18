from django.conf import settings
from django.db import models
from farms.models import Farm


class WeatherConfiguration(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    enabled = models.BooleanField(default=False)
    mode = models.CharField(max_length=10, choices=[('public', 'Public API'), ('customer', 'Customer API')], default='public')
    encrypted_key = models.TextField(blank=True)


class WeatherSnapshot(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    payload = models.JSONField()
    retrieved_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['user', 'farm'], name='unique_weather_snapshot')]
