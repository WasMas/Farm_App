from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from rest_framework.permissions import BasePermission
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import timedelta
from farms.models import Farm, Field
from crops.models import CropCycle
from activities.models import Activity
from .serializers import RegistrationSerializer, UserSerializer, LoginSerializer
from .models import User


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (
                request.user.role == User.Role.ADMIN
                or request.user.is_staff
                or request.user.is_superuser
            )
        )


class AdminDashboardView(APIView):
    permission_classes = [IsAdmin]

    def get(self, request):
        week = timezone.now() - timedelta(days=7)
        recent_users = User.objects.order_by('-date_joined')[:10]

        return Response({
            'counts': {
                'users': User.objects.count(),
                'farms': Farm.objects.count(),
                'fields': Field.objects.count(),
                'active_crops': CropCycle.objects.filter(status=CropCycle.Status.ACTIVE).count(),
                'activities': Activity.objects.count(),
                'new_users_7d': User.objects.filter(date_joined__gte=week).count(),
            },
            'users': [
                {
                    'id': user.id,
                    'username': user.username,
                    'name': user.first_name,
                    'email': user.email,
                    'role': user.role,
                    'is_staff': user.is_staff,
                    'is_active': user.is_active,
                    'date_joined': user.date_joined,
                    'last_login': user.last_login,
                }
                for user in recent_users
            ],
        })


class AdminUserDetailView(APIView):
    permission_classes = [IsAdmin]

    def patch(self, request, pk):
        user = get_object_or_404(User, pk=pk)
        role = request.data.get('role')
        is_active = request.data.get('is_active')

        if role is not None:
            if role not in {User.Role.ADMIN, User.Role.FARMER, User.Role.EXPERT}:
                return Response(
                    {'role': 'Choose admin, farmer, or expert.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user.role = role

        if is_active is not None:
            if not isinstance(is_active, bool):
                return Response(
                    {'is_active': 'Use true or false.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user.is_active = is_active

        user.save()

        return Response({
            'id': user.id,
            'username': user.username,
            'name': user.first_name,
            'email': user.email,
            'role': user.role,
            'is_staff': user.is_staff,
            'is_active': user.is_active,
            'date_joined': user.date_joined,
            'last_login': user.last_login,
        })


class RegisterView(generics.CreateAPIView):
    serializer_class = RegistrationSerializer
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = 'auth'


class LoginView(TokenObtainPairView):
    serializer_class = LoginSerializer
    throttle_scope = 'auth'


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class LogoutView(APIView):
    def post(self, request):
        try:
            token = RefreshToken(request.data.get('refresh', ''))
            if str(token['user_id']) != str(request.user.pk):
                return Response({'detail': 'This token belongs to another account.'}, status=403)
            token.blacklist()
        except TokenError:
            return Response({'detail': 'Invalid or expired refresh token.'}, status=400)
        return Response(status=status.HTTP_204_NO_CONTENT)
