from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = 'admin', 'Administrator'
        FARMER = 'farmer', 'Farmer'
        EXPERT = 'expert', 'Agricultural expert'

    email = models.EmailField(unique=True)
    role = models.CharField(max_length=12, choices=Role, default=Role.FARMER)
