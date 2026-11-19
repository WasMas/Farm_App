from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from crops.models import CropCycle
from farms.access import visible_farms
from .models import PredictionRecord
from .services import disease_prediction, yield_prediction


class DiseasePredictionView(APIView):
    def post(self, request):
        image = request.FILES.get('image')
        if image is None:
            raise ValidationError({'image': 'Upload a clear plant-leaf image.'})
        if image.size > 10 * 1024 * 1024:
            raise ValidationError({'image': 'The image must be smaller than 10 MB.'})
        try:
            image_bytes = image.read()
            result = disease_prediction(request.data, image_bytes)
        except ValueError as exc:
            raise ValidationError({'image': str(exc)}) from exc
        record = PredictionRecord.objects.create(
            user=request.user,
            kind=PredictionRecord.Kind.DISEASE,
            result=result,
        )
        image.seek(0)
        record.image.save(image.name, image, save=True)
        return Response(result)


class YieldPredictionView(APIView):
    def post(self, request):
        try:
            cycle_id = int(request.data.get('cycle'))
        except (TypeError, ValueError) as exc:
            raise ValidationError({'cycle': 'Provide a valid planting cycle id.'}) from exc
        cycle = CropCycle.objects.filter(
            pk=cycle_id,
            field__farm__in=visible_farms(request.user),
        ).select_related('crop_type').first()
        if cycle is None:
            raise ValidationError({'cycle': 'Planting cycle not found.'})
        result = yield_prediction(cycle)
        PredictionRecord.objects.create(
            user=request.user,
            cycle=cycle,
            kind=PredictionRecord.Kind.YIELD,
            result=result,
        )
        return Response(result)


class PredictionHistoryView(APIView):
    def get(self, request):
        records = PredictionRecord.objects.filter(
            user=request.user,
        ).select_related('cycle')
        return Response([
            {
                'id': record.id,
                'kind': record.kind,
                'result': record.result,
                'image': request.build_absolute_uri(record.image.url) if record.image else None,
                'cycle': record.cycle_id,
                'created_at': record.created_at,
            }
            for record in records[:50]
        ])
