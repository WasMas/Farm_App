from django.contrib import admin
from .models import Activity


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['date', 'kind', 'cycle', 'quantity', 'unit', 'recorded_by']
    list_filter = ['kind', 'date']
