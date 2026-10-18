from django.contrib import admin
from django.urls import path
from core.views import HealthView

urlpatterns = [path('admin/', admin.site.urls), path('api/health/', HealthView.as_view())]
admin.site.site_header = 'Fieldbook administration'
admin.site.site_title = 'Fieldbook'
