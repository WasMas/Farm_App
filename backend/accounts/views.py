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
from core.models import AuditEvent
from recommendations.models import Recommendation
from .serializers import (
    RegistrationSerializer,
    UserSerializer,
    LoginSerializer,
    OwnerSerializer,
    UserSummarySerializer,
)
from .models import User
from core.models import record_event


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
                'pending_recommendations': Recommendation.objects.filter(
                    status=Recommendation.Status.PENDING,
                ).count(),
                'ai_recommendations': Recommendation.objects.filter(
                    source='ai',
                ).count(),
                'audit_events': AuditEvent.objects.count(),
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

    def post(self, request):
        serializer = OwnerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        owner = serializer.save()
        record_event(request.user, owner, 'create_owner')
        return Response(UserSummarySerializer(owner).data, status=status.HTTP_201_CREATED)


class AdminUserDetailView(APIView):
    permission_classes = [IsAdmin]

    def patch(self, request, pk):
        user = get_object_or_404(User, pk=pk)
        role = request.data.get('role')
        is_active = request.data.get('is_active')

        if role is not None:
            if role not in {
                User.Role.ADMIN,
                User.Role.OWNER,
                User.Role.WORKER,
            }:
                return Response(
                    {'role': 'Choose admin, owner, or worker.'},
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
        record_event(request.user, user, 'update_role' if role is not None else 'update')

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


class AdminAuditView(APIView):
    permission_classes = [IsAdmin]

    def _summary(self, event):
        action_labels = {
            'create': 'Created',
            'update': 'Updated',
            'delete': 'Deleted',
            'create_owner': 'Created owner account',
            'create_worker': 'Created worker account',
            'assign': 'Assigned field worker',
            'share': 'Shared farm access',
            'unshare': 'Removed farm access',
            'update_role': 'Changed user role',
            'login': 'Signed in',
            'logout': 'Signed out',
            'profile_update': 'Updated profile',
            'weather_update': 'Updated weather configuration',
            'chat_create': 'Created AI chat',
            'chat_update': 'Renamed AI chat',
            'chat_delete': 'Deleted AI chat',
            'chat_message': 'Sent AI chat message',
            'disease_predict': 'Ran disease prediction',
            'yield_predict': 'Ran yield prediction',
            'generate': 'Generated recommendation',
            'accept': 'Accepted recommendation',
            'refuse': 'Refused recommendation',
        }
        entity_labels = {
            'accounts.User': 'user',
            'activities.Activity': 'activity',
            'ai_chat.ChatConversation': 'conversation',
            'ai_chat.ChatMessage': 'chat message',
            'crops.CropCycle': 'planting',
            'crops.CropType': 'crop reference',
            'farms.Farm': 'farm',
            'farms.Field': 'field',
            'farms.FieldAssignment': 'field assignment',
            'farms.FarmMembership': 'farm access',
            'predictions.PredictionRecord': 'prediction',
            'recommendations.Recommendation': 'recommendation',
            'weather.WeatherConfiguration': 'weather settings',
        }
        actor = event.actor.username if event.actor else 'System'
        action = action_labels.get(event.action, event.action.replace('_', ' ').title())
        entity = entity_labels.get(event.entity, event.entity.split('.')[-1])

        label = ''
        try:
            app_label, model_name = event.entity.split('.', 1)
            from django.apps import apps
            model = apps.get_model(app_label, model_name)
            obj = model.objects.filter(pk=event.object_id).first()
            if obj:
                for attr in ('username', 'name', 'title', 'variety', 'notes'):
                    value = getattr(obj, attr, None)
                    if isinstance(value, str) and value.strip():
                        label = f' "{value.strip()}"'
                        break
        except (ValueError, LookupError):
            pass

        return f'{actor} {action.lower()} {entity}{label}'

    def get(self, request):
        events = AuditEvent.objects.select_related('actor')
        action = request.query_params.get('action', '').strip()
        actor = request.query_params.get('actor', '').strip()
        entity = request.query_params.get('entity', '').strip()
        start = request.query_params.get('start', '').strip()
        end = request.query_params.get('end', '').strip()

        if action:
            events = events.filter(action__icontains=action)
        if actor:
            events = events.filter(actor__username__icontains=actor)
        if entity:
            events = events.filter(entity__icontains=entity)
        if start:
            events = events.filter(recorded_at__date__gte=start)
        if end:
            events = events.filter(recorded_at__date__lte=end)

        events = events[:100]
        return Response([
            {
                'id': event.id,
                'actor': event.actor.username if event.actor else 'System',
                'action': event.action,
                'entity': event.entity,
                'object_id': event.object_id,
                'recorded_at': event.recorded_at,
                'summary': self._summary(event),
            }
            for event in events
        ])


class RegisterView(generics.CreateAPIView):
    serializer_class = RegistrationSerializer
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_scope = 'auth'


class LoginView(TokenObtainPairView):
    serializer_class = LoginSerializer
    throttle_scope = 'auth'

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            user = User.objects.filter(username=request.data.get('username')).first()
            if user:
                record_event(user, user, 'login')
        return response


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def perform_update(self, serializer):
        user = serializer.save()
        record_event(self.request.user, user, 'profile_update')


class LogoutView(APIView):
    def post(self, request):
        try:
            token = RefreshToken(request.data.get('refresh', ''))
            if str(token['user_id']) != str(request.user.pk):
                return Response({'detail': 'This token belongs to another account.'}, status=403)
            token.blacklist()
            record_event(request.user, request.user, 'logout')
        except TokenError:
            return Response({'detail': 'Invalid or expired refresh token.'}, status=400)
        return Response(status=status.HTTP_204_NO_CONTENT)
