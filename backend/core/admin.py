from django.contrib import admin
from .models import AuditEvent


@admin.register(AuditEvent)
class AuditEventAdmin(admin.ModelAdmin):
    list_display = ['recorded_at', 'actor', 'action', 'entity', 'object_id']
    list_filter = ['action', 'entity']
    readonly_fields = ['recorded_at', 'actor', 'action', 'entity', 'object_id']

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False
