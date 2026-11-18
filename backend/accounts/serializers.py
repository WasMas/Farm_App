from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import User


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(
        source='first_name',
        required=False,
        max_length=150
    )

    profile_image = serializers.ImageField(
        required=False,
        allow_null=True
    )

    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'name',
            'role',
            'is_staff',
            'bio',
            'profile_image',
            'profile_image_url',
        ]

        read_only_fields = [
            'id',
            'username',
            'role',
            'is_staff',
        ]

    def validate_profile_image_url(self, value):
        if value and not value.startswith(('https://', 'http://')):
            raise serializers.ValidationError(
                'Please provide a valid HTTP or HTTPS image URL.'
            )
        return value

class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    name = serializers.CharField(source='first_name', max_length=150)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'name', 'password']
        read_only_fields = ['id']

    def validate(self, attrs):
        validate_password(attrs['password'], User(**{k: v for k, v in attrs.items() if k != 'password'}))
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class LoginSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        return data
