
import logging

from django.shortcuts import get_object_or_404

from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import ChatConversation, ChatMessage

from .serializers import (
    ChatConversationSerializer,
    ChatMessageSerializer,
    ChatMessageCreateSerializer,
)

from .services.gemini_service import generate_gemini_reply
from core.models import record_event


logger = logging.getLogger(__name__)


class ChatConversationListCreateView(generics.ListCreateAPIView):
    serializer_class = ChatConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ChatConversation.objects.filter(
            user=self.request.user
        )

    def perform_create(self, serializer):
        conversation = serializer.save(user=self.request.user)
        record_event(self.request.user, conversation, 'chat_create')


class ChatConversationDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ChatConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ChatConversation.objects.filter(
            user=self.request.user
        )

    def perform_update(self, serializer):
        conversation = serializer.save()
        record_event(self.request.user, conversation, 'chat_update')

    def perform_destroy(self, instance):
        record_event(self.request.user, instance, 'chat_delete')
        instance.delete()


class ChatMessageListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    throttle_scope = 'ai_chat'

    def get_queryset(self):
        return ChatMessage.objects.filter(
            conversation__user=self.request.user,
            conversation_id=self.kwargs['conversation_id'],
        ).select_related('conversation')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ChatMessageCreateSerializer

        return ChatMessageSerializer

    def create(self, request, *args, **kwargs):
        conversation = get_object_or_404(
            ChatConversation,
            pk=self.kwargs['conversation_id'],
            user=request.user,
        )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Save the user's message first.
        user_message = serializer.save(
            conversation=conversation,
            sender='user',
        )

        conversation.save(update_fields=['updated_at'])
        record_event(request.user, user_message, 'chat_message')

        # Retrieve up to 12 previous messages.
        history = list(
            ChatMessage.objects.filter(
                conversation=conversation
            )
            .exclude(pk=user_message.pk)
            .order_by('-created_at')[:12]
        )

        history.reverse()

        # Generate the AI response.
        try:
            answer = generate_gemini_reply(
                history=history,
                user_message=user_message,
            )

        except Exception:
            logger.exception('Gemini chatbot request failed.')

            return Response(
                {
                    'detail': (
                        'The AI assistant is temporarily unavailable. '
                        'Your message was saved. Please try again later.'
                    ),
                    'user_message': ChatMessageSerializer(
                        user_message,
                        context=self.get_serializer_context(),
                    ).data,
                },
                status=status.HTTP_502_BAD_GATEWAY,
            )

        # Save the AI response.
        assistant_message = ChatMessage.objects.create(
            conversation=conversation,
            sender='assistant',
            content=answer,
        )

        conversation.save(update_fields=['updated_at'])

        return Response(
            {
                'user_message': ChatMessageSerializer(
                    user_message,
                    context=self.get_serializer_context(),
                ).data,
                'assistant_message': ChatMessageSerializer(
                    assistant_message,
                    context=self.get_serializer_context(),
                ).data,
            },
            status=status.HTTP_201_CREATED,
        )
