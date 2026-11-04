from rest_framework import serializers
from .models import WeatherConfiguration, WeatherSnapshot
from .services import encrypt_key


class WeatherConfigurationSerializer(serializers.ModelSerializer):
    api_key = serializers.CharField(write_only=True, required=False, allow_blank=True, max_length=512)
    clear_key = serializers.BooleanField(write_only=True, required=False, default=False)
    has_key = serializers.SerializerMethodField()

    class Meta:
        model = WeatherConfiguration
        fields = ['enabled', 'mode', 'api_key', 'clear_key', 'has_key']

    def get_has_key(self, obj):
        return bool(obj.encrypted_key)

    def update(self, instance, validated_data):
        key = validated_data.pop('api_key', '')
        clear = validated_data.pop('clear_key', False)
        if key:
            instance.encrypted_key = encrypt_key(key)
        elif clear:
            instance.encrypted_key = ''
        result = super().update(instance, validated_data)
        WeatherSnapshot.objects.filter(user=instance.user).delete()
        return result


class WeatherQuery(serializers.Serializer):
    farm = serializers.IntegerField(min_value=1)
    refresh = serializers.BooleanField(required=False, default=False)
