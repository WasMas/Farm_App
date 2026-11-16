
from rest_framework import serializers
from PIL import Image, UnidentifiedImageError

from .models import ChatConversation, ChatMessage


class ChatConversationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatConversation
        fields = (
            'id',
            'title',
            'created_at',
            'updated_at',
        )
        read_only_fields = (
            'id',
            'created_at',
            'updated_at',
        )
        extra_kwargs = {
            'title': {'required': False},
        }


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = (
            'id',
            'sender',
            'content',
            'image',
            'created_at',
        )
        read_only_fields = fields


class ChatMessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = (
            'content',
            'image',
        )
        extra_kwargs = {
            'content': {
                'required': False,
                'allow_blank': True,
            },
            'image': {
                'required': False,
                'allow_null': True,
            },
        }

    def validate(self, attrs):
        content = (attrs.get('content') or '').strip()
        image = attrs.get('image')

        if not content and not image:
            raise serializers.ValidationError(
                'Please enter a message or attach an image.'
            )

        if image:
            if image.size > 8 * 1024 * 1024:
                raise serializers.ValidationError(
                    'Images must be smaller than 8 MB.'
                )

            try:
                image.seek(0)

                with Image.open(image) as img:
                    if img.format not in ('JPEG', 'PNG', 'WEBP'):
                        raise serializers.ValidationError(
                            'Only JPG, PNG and WEBP images are supported.'
                        )

                    img.verify()

                image.seek(0)

            except (UnidentifiedImageError, OSError):
                raise serializers.ValidationError(
                    'The uploaded file is not a valid image.'
                )

        attrs['content'] = content
        return attrs
