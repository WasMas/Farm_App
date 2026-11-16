
from django.conf import settings
from django.db import models


class ChatConversation(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='ai_chat_conversations',
    )

    title = models.CharField(
        max_length=150,
        default='New conversation',
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f'{self.title} - {self.user}'


class ChatMessage(models.Model):
    class Sender(models.TextChoices):
        USER = 'user', 'User'
        ASSISTANT = 'assistant', 'Assistant'

    conversation = models.ForeignKey(
        ChatConversation,
        on_delete=models.CASCADE,
        related_name='messages',
    )

    sender = models.CharField(
        max_length=10,
        choices=Sender.choices,
    )

    content = models.TextField(blank=True, default='')

    image = models.ImageField(
        upload_to='chat_images/%Y/%m/',
        blank=True,
        null=True,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        indexes = [
            models.Index(
                fields=['conversation', 'created_at'],
                name='chat_msg_conv_date_idx',
            ),
        ]

    def __str__(self):
        return f'{self.sender} message - Conversation {self.conversation_id}'
