from django.contrib.auth.models import Group, Permission
from django.db.models.signals import post_migrate, post_save
from django.dispatch import receiver
from .models import User


@receiver(post_migrate)
def configure_groups(**kwargs):
    for role, label in User.Role.choices:
        group, _ = Group.objects.get_or_create(name=label)
        permissions = Permission.objects.filter(content_type__app_label__in=['farms', 'crops', 'activities', 'weather'])
        if role == User.Role.ADMIN:
            permissions = Permission.objects.all()
        group.permissions.set(permissions)


@receiver(post_save, sender=User)
def assign_role_group(sender, instance, **kwargs):
    group, _ = Group.objects.get_or_create(name=instance.get_role_display())
    instance.groups.remove(*Group.objects.filter(name__in=User.Role.labels).exclude(pk=group.pk))
    instance.groups.add(group)
