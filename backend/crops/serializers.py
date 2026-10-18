from django.db.models import Sum
from django.utils import timezone
from rest_framework import serializers
from farms.access import visible_farms, can_work
from farms.models import Field
from .models import CropType, CropCycle


class CropTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = CropType
        fields = ['id', 'name', 'description']

    def validate_name(self, value):
        if CropType.objects.filter(name__iexact=value).exclude(pk=getattr(self.instance, 'pk', None)).exists():
            raise serializers.ValidationError('This crop type already exists.')
        return value


class CropCycleSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop_type.name', read_only=True)
    field_name = serializers.CharField(source='field.name', read_only=True)
    farm_name = serializers.CharField(source='field.farm.name', read_only=True)
    farm = serializers.IntegerField(source='field.farm_id', read_only=True)
    can_edit = serializers.SerializerMethodField()

    class Meta:
        model = CropCycle
        fields = ['id', 'field', 'field_name', 'farm', 'farm_name', 'crop_type', 'crop_name', 'variety', 'planting_date', 'end_date', 'area', 'current_stage', 'status', 'can_edit']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.context.get('request'):
            self.fields['field'].queryset = Field.objects.filter(farm__in=visible_farms(self.context['request'].user))

    def get_can_edit(self, obj):
        return can_work(self.context['request'].user, obj.field.farm)

    def validate(self, attrs):
        field = attrs.get('field', getattr(self.instance, 'field', None))
        if not can_work(self.context['request'].user, field.farm):
            raise serializers.ValidationError({'field': 'You have read-only access.'})
        if self.instance:
            if field.pk != self.instance.field_id or attrs.get('crop_type', self.instance.crop_type).pk != self.instance.crop_type_id:
                raise serializers.ValidationError('Field and crop type are fixed for a planting cycle. Create a new cycle instead.')
        planting = attrs.get('planting_date', getattr(self.instance, 'planting_date', None))
        end = attrs.get('end_date', getattr(self.instance, 'end_date', None))
        status = attrs.get('status', getattr(self.instance, 'status', 'active'))
        today = timezone.localdate()
        if planting > today:
            raise serializers.ValidationError({'planting_date': 'Record a planting that has already taken place.'})
        if status == 'completed' and not end:
            raise serializers.ValidationError({'end_date': 'A completed cycle needs an end date.'})
        if end and (end < planting or end > today or status == 'active'):
            raise serializers.ValidationError({'end_date': 'Use a date between planting and today for a completed cycle.'})
        field = Field.objects.select_for_update().get(pk=field.pk)
        area = attrs.get('area', getattr(self.instance, 'area', 0))
        used = field.cycles.filter(status='active').exclude(pk=getattr(self.instance, 'pk', None)).aggregate(total=Sum('area'))['total'] or 0
        if area > field.area or (status == 'active' and used + area > field.area):
            raise serializers.ValidationError({'area': 'Active planting areas cannot exceed the field area.'})
        return attrs
