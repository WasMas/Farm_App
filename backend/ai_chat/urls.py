
from django.urls import include, path

from .views import (
    ChatConversationListCreateView,
    ChatConversationDetailView,
    ChatMessageListCreateView,
)


urlpatterns = [
    path(
        'conversations/',
        ChatConversationListCreateView.as_view(),
        name='chat-conversation-list',
    ),

    path(
        'conversations/<int:pk>/',
        ChatConversationDetailView.as_view(),
        name='chat-conversation-detail',
    ),

    path(
        'conversations/<int:conversation_id>/messages/',
        ChatMessageListCreateView.as_view(),
        name='chat-message-list',
    ),
]
