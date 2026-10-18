from django.shortcuts import get_object_or_404
from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from farms.access import visible_farms
from .models import WeatherConfiguration
from .serializers import WeatherConfigurationSerializer, WeatherQuery
from .services import weather_for


class WeatherConfigurationView(generics.RetrieveUpdateAPIView):
    serializer_class = WeatherConfigurationSerializer

    def get_object(self):
        return WeatherConfiguration.objects.get_or_create(user=self.request.user)[0]


class WeatherView(APIView):
    throttle_scope = 'weather'

    def get(self, request):
        query = WeatherQuery(data=request.query_params)
        query.is_valid(raise_exception=True)
        farm = get_object_or_404(visible_farms(request.user), pk=query.validated_data['farm'])
        config, _ = WeatherConfiguration.objects.get_or_create(user=request.user)
        return Response(weather_for(farm, config, force=query.validated_data['refresh']))
