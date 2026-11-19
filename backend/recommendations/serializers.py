from rest_framework import serializers
from .models import Recommendation


class RecommendationSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='cycle.crop_type.name', read_only=True)
    field_name = serializers.CharField(source='cycle.field.name', read_only=True)
    farm_name = serializers.CharField(source='cycle.field.farm.name', read_only=True)

    class Meta:
        model = Recommendation
        fields = [
            'id', 'cycle', 'crop_name', 'field_name', 'farm_name', 'kind',
            'title', 'message', 'proposed_stage', 'activity_kind', 'quantity',
            'unit', 'due_date', 'source', 'status', 'decided_by', 'decided_at',
            'created_at',
        ]
        read_only_fields = fields
