from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class FieldbookUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (('Fieldbook', {'fields': ('role',)}),)
    add_fieldsets = UserAdmin.add_fieldsets + (('Fieldbook', {'fields': ('email', 'role')}),)
    list_display = ('username', 'email', 'role', 'is_active', 'is_staff')
