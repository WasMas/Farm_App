from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from farms.views import FarmViewSet, FieldViewSet
from crops.views import CropTypeViewSet, CropCycleViewSet
from core.views import HealthView
from accounts.views import RegisterView, LoginView, LogoutView, MeView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [path('admin/', admin.site.urls), path('api/health/', HealthView.as_view())]
urlpatterns += [path('api/auth/register/', RegisterView.as_view()), path('api/auth/login/', LoginView.as_view()),
                path('api/auth/refresh/', TokenRefreshView.as_view()), path('api/auth/logout/', LogoutView.as_view()),
                path('api/auth/me/', MeView.as_view())]
admin.site.site_header = 'Fieldbook administration'
admin.site.site_title = 'Fieldbook'
router = DefaultRouter()
router.register('farms', FarmViewSet, basename='farm')
router.register('fields', FieldViewSet, basename='field')
router.register('crop-types', CropTypeViewSet, basename='crop-type')
router.register('crop-cycles', CropCycleViewSet, basename='crop-cycle')
urlpatterns += [path('api/', include(router.urls))]
