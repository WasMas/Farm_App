from django.utils import timezone
from rest_framework import serializers
from crops.models import CropCycle
from farms.access import visible_farms, can_work_field
from .models import Activity

UNITS = {'irrigation': {'m3', 'l'}, 'fertilization': {'kg', 'g', 'l'}, 'treatment': {'kg', 'g', 'l', 'ml'}, 'harvest': {'kg', 't', 'items'}}


class ActivitySerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='cycle.crop_type.name', read_only=True)
    field_name = serializers.CharField(source='cycle.field.name', read_only=True)
    farm_name = serializers.CharField(source='cycle.field.farm.name', read_only=True)
    author_name = serializers.CharField(source='recorded_by.username', read_only=True)
    can_edit = serializers.SerializerMethodField()

    class Meta:
        model = Activity
        fields = ['id', 'cycle', 'kind', 'date', 'quantity', 'unit', 'product', 'notes', 'recorded_by', 'author_name', 'crop_name', 'field_name', 'farm_name', 'can_edit']
        read_only_fields = ['recorded_by']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.context.get('request'):
            self.fields['cycle'].queryset = CropCycle.objects.filter(field__farm__in=visible_farms(self.context['request'].user))

    def get_can_edit(self, obj):
        return can_work_field(self.context['request'].user, obj.cycle.field)

    def validate(self, attrs):
        def value(key, default=None):
            return attrs.get(key, getattr(self.instance, key, default))
        cycle, kind, date = value('cycle'), value('kind'), value('date')
        if not can_work_field(self.context['request'].user, cycle.field):
            raise serializers.ValidationError({'cycle': 'You have read-only access.'})
        if self.instance and cycle.pk != self.instance.cycle_id:
            raise serializers.ValidationError({'cycle': 'An activity cannot be moved to another planting.'})
        if date > timezone.localdate() or date < cycle.planting_date or (cycle.end_date and date > cycle.end_date):
            raise serializers.ValidationError({'date': 'Use a date within this planting season, up to today.'})
        quantity, unit = value('quantity'), value('unit', '')
        if kind == 'observation':
            if not value('notes', '').strip():
                raise serializers.ValidationError({'notes': 'Describe what you observed.'})
            if quantity is not None or unit:
                raise serializers.ValidationError({'quantity': 'Observations use notes; leave quantity and unit empty.'})
        elif quantity is None or unit not in UNITS[kind]:
            raise serializers.ValidationError({'quantity': 'Provide a positive quantity and an appropriate unit.', 'unit': sorted(UNITS[kind])})
        if kind in ['fertilization', 'treatment'] and not value('product', '').strip():
            raise serializers.ValidationError({'product': 'Record the product used.'})
        return attrs


class ActivityFilters(serializers.Serializer):
    cycle = serializers.IntegerField(min_value=1, required=False)
    farm = serializers.IntegerField(min_value=1, required=False)
    kind = serializers.ChoiceField(choices=Activity.Kind, required=False)
    start = serializers.DateField(required=False)
    end = serializers.DateField(required=False)
