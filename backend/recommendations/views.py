from datetime import date

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from farms.access import can_manage, can_work_field
from accounts.models import User
from .models import Recommendation
from .serializers import RecommendationSerializer
from .services import (
    decide_recommendation,
    generate_recommendations,
    visible_recommendation_cycles,
)
from core.models import record_event


def _visible_recommendation(user, pk):
    recommendation = get_object_or_404(
        Recommendation.objects.select_related('cycle__field__farm', 'cycle__crop_type'),
        pk=pk,
    )
    if not can_work_field(user, recommendation.cycle.field):
        raise PermissionDenied('You do not have access to this recommendation.')
    return recommendation


class RecommendationListView(APIView):
    def get(self, request):
        recommendations = Recommendation.objects.filter(
            cycle__in=visible_recommendation_cycles(request.user, active_only=False)
        ).select_related('cycle__field__farm', 'cycle__crop_type', 'decided_by')
        recommendations = recommendations.order_by('due_date', 'created_at', 'id')
        return Response(RecommendationSerializer(recommendations, many=True).data)

    def post(self, request):
        as_of = request.data.get('as_of')
        try:
            parsed_date = date.fromisoformat(as_of) if as_of else None
        except ValueError as exc:
            raise ValidationError({'as_of': 'Use YYYY-MM-DD.'}) from exc
        use_ai = request.data.get('use_ai', False)
        if not isinstance(use_ai, bool):
            raise ValidationError({'use_ai': 'Use true or false.'})
        created = generate_recommendations(request.user, parsed_date, use_ai=use_ai)
        for recommendation in created:
            record_event(request.user, recommendation, 'generate')
        return Response(RecommendationSerializer(created, many=True).data, status=status.HTTP_201_CREATED)


class RecommendationDecisionView(APIView):
    def post(self, request, pk, decision):
        recommendation = _visible_recommendation(request.user, pk)
        if not can_manage(request.user, recommendation.cycle.field.farm):
            raise PermissionDenied('Only the farm owner or a manager may decide recommendations.')
        if decision not in {'accept', 'refuse'}:
            raise ValidationError({'decision': 'Choose accept or refuse.'})
        effective_date = request.data.get('as_of')
        if effective_date:
            try:
                effective_date = date.fromisoformat(effective_date)
            except ValueError as exc:
                raise ValidationError({'as_of': 'Use YYYY-MM-DD.'}) from exc
        updated = decide_recommendation(
            recommendation,
            request.user,
            decision == 'accept',
            effective_date,
        )
        return Response(RecommendationSerializer(updated).data)
