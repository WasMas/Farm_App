from django.contrib import admin
from .models import Farm, Field, FarmMembership

admin.site.register([Farm, Field, FarmMembership])
