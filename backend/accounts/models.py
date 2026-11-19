from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = 'admin', 'Administrator'
        OWNER = 'owner', 'Farm owner'
        WORKER = 'worker', 'Farm worker'

    email = models.EmailField(unique=True)
    role = models.CharField(max_length=12, choices=Role, default=Role.OWNER)

    bio = models.TextField(max_length=500, blank=True, default='')

    profile_image = models.ImageField(
        upload_to='profile_pictures/',
        blank=True,
        null=True
    )

    profile_image_url = models.URLField(
        max_length=500,
        blank=True,
        default=''
    )
    def save(self, *args, **kwargs):
        if self.is_superuser:
            self.role = self.Role.ADMIN
        self.is_staff = self.role == self.Role.ADMIN
        if kwargs.get('update_fields') is not None:
            kwargs['update_fields'] = set(kwargs['update_fields']) | {'role', 'is_staff'}
        super().save(*args, **kwargs)
