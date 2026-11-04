from django.db.models import Sum
from rest_framework import serializers
from .models import Farm, Field, FarmMembership
from .access import visible_farms, can_manage, can_work


class FarmSerializer(serializers.ModelSerializer):
    field_count = serializers.IntegerField(source='fields.count', read_only=True)
    owner_name = serializers.CharField(source='owner.username', read_only=True)
    can_edit = serializers.SerializerMethodField()
    can_share = serializers.SerializerMethodField()
    can_work = serializers.SerializerMethodField()

    class Meta:
        model = Farm
        fields = ['id', 'name', 'location', 'total_area', 'latitude', 'longitude', 'owner', 'owner_name', 'field_count', 'can_edit', 'can_share', 'can_work']
        read_only_fields = ['owner']

    def get_can_edit(self, obj):
        return can_manage(self.context['request'].user, obj)

    def get_can_share(self, obj):
        user = self.context['request'].user
        return user.is_staff or (user.role != 'expert' and obj.owner_id == user.pk)

    def get_can_work(self, obj):
        return can_work(self.context['request'].user, obj)

    def validate(self, attrs):
        lat = attrs.get('latitude', getattr(self.instance, 'latitude', None))
        lon = attrs.get('longitude', getattr(self.instance, 'longitude', None))
        if (lat is None) != (lon is None):
            raise serializers.ValidationError('Provide both latitude and longitude, or leave both empty.')
        if self.instance and 'total_area' in attrs:
            used = self.instance.fields.aggregate(total=Sum('area'))['total'] or 0
            if attrs['total_area'] < used:
                raise serializers.ValidationError({'total_area': 'Farm area cannot be smaller than its fields combined.'})
        return attrs


class FieldSerializer(serializers.ModelSerializer):
    farm_name = serializers.CharField(source='farm.name', read_only=True)
    can_edit = serializers.SerializerMethodField()

    class Meta:
        model = Field
        fields = ['id', 'farm', 'farm_name', 'name', 'area', 'soil_type', 'can_edit']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.context.get('request'):
            self.fields['farm'].queryset = visible_farms(self.context['request'].user)

    def get_can_edit(self, obj):
        return can_work(self.context['request'].user, obj.farm)

    def validate(self, attrs):
        farm = attrs.get('farm', getattr(self.instance, 'farm', None))
        if self.instance and farm.pk != self.instance.farm_id:
            raise serializers.ValidationError({'farm': 'A field cannot be moved between farms.'})
        if not can_work(self.context['request'].user, farm):
            raise serializers.ValidationError({'farm': 'You have read-only access to this farm.'})
        # Called inside the view's atomic create/update transaction.
        farm = Farm.objects.select_for_update().get(pk=farm.pk)
        used = farm.fields.exclude(pk=getattr(self.instance, 'pk', None)).aggregate(total=Sum('area'))['total'] or 0
        area = attrs.get('area', getattr(self.instance, 'area', 0))
        if self.instance:
            planted = self.instance.cycles.filter(status='active').aggregate(total=Sum('area'))['total'] or 0
            if area < planted:
                raise serializers.ValidationError({'area': 'Field area cannot be smaller than its active plantings.'})
        if used + area > farm.total_area:
            raise serializers.ValidationError({'area': 'Combined field area exceeds the farm area.'})
        return attrs


class MembershipSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = FarmMembership
        fields = ['id', 'user', 'username', 'role']
        read_only_fields = ['id', 'user']
