from rest_framework.views import APIView
from rest_framework.response import Response
from core.query import positive_id
from farms.access import visible_farms
from crops.models import CropCycle
from crops.serializers import CropCycleSerializer
from activities.models import Activity
from activities.serializers import ActivitySerializer
from .services import summarize


class DashboardView(APIView):
    def get(self, request):
        farms = visible_farms(request.user)
        if "farm" in request.query_params:
            farms = farms.filter(pk=positive_id(request.query_params["farm"], "farm"))
        data = summarize(farms)
        cycles = CropCycle.objects.filter(field__farm__in=farms, status='active').select_related('field__farm', 'crop_type')[:4]
        recent = Activity.objects.filter(cycle__field__farm__in=farms).select_related('cycle__field__farm', 'cycle__crop_type', 'recorded_by')[:5]
        data['plantings'] = CropCycleSerializer(cycles, many=True, context={'request': request}).data
        data['recent_activities'] = ActivitySerializer(recent, many=True, context={'request': request}).data
        return Response(data)
