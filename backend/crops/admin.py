from django.contrib import admin
from .models import CropType, CropCycle

admin.site.register([CropType, CropCycle])
