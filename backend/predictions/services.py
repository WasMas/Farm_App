from datetime import timedelta
from decimal import Decimal
from io import BytesIO

from activities.models import Activity
from PIL import Image
import torch
from transformers import AutoImageProcessor, AutoModelForImageClassification


MODEL_ID = 'LourivalGontijo/plantvillage-mobilenetv2'
CONFIDENCE_THRESHOLD = 0.85
_processor = None
_model = None


def get_disease_model():
    global _processor, _model
    if _processor is None or _model is None:
        _processor = AutoImageProcessor.from_pretrained(MODEL_ID, revision='9e3c97cf1e63e2a665a27c7bccd0ac067a2dbe5d')
        _model = AutoModelForImageClassification.from_pretrained(MODEL_ID, revision='9e3c97cf1e63e2a665a27c7bccd0ac067a2dbe5d')
        _model.eval()
    return _processor, _model


def label_to_readable(label):
    readable = label.replace('___', ' - ').replace('_', ' ')
    return readable.replace('  ', ' ')


def disease_prediction(data=None, image_bytes=None):
    if image_bytes is None:
        symptoms = str((data or {}).get('symptoms', '')).strip()
        if symptoms:
            return {
                'prediction': 'Image required for disease classification',
                'probability': 0.0,
                'actions': [
                    'Upload a clear photo of one affected leaf',
                    'Use daylight and a plain background',
                    'Symptoms alone cannot identify a disease reliably',
                ],
                'source': 'plantvillage-mobilenetv2',
            }
        return {
            'prediction': 'Image required',
            'probability': 0.0,
            'actions': ['Upload a clear photo of one affected leaf'],
            'source': 'plantvillage-mobilenetv2',
        }

    try:
        image = Image.open(BytesIO(image_bytes)).convert('RGB')
    except Exception as exc:
        raise ValueError('The uploaded image is invalid or unsupported.') from exc

    processor, model = get_disease_model()
    inputs = processor(images=image, return_tensors='pt')
    with torch.no_grad():
        probabilities = torch.softmax(model(**inputs).logits, dim=-1)[0]
    score, index = torch.max(probabilities, dim=0)
    probability = float(score.item())
    label = model.config.id2label[index.item()]

    if probability < CONFIDENCE_THRESHOLD:
        return {
            'prediction': 'Not sure',
            'probability': round(probability, 4),
            'top_label': label_to_readable(label),
            'actions': [
                'Retake the photo with a single leaf centred',
                'Use daylight and avoid blur or a busy background',
                'Ask a farm specialist for confirmation',
            ],
            'source': 'plantvillage-mobilenetv2',
            'model_id': MODEL_ID,
            'disclaimer': 'A pretrained PlantVillage classifier, not a diagnosis.',
        }

    return {
        'prediction': label_to_readable(label),
        'probability': round(probability, 4),
        'actions': [
            'Inspect the affected area and surrounding leaves',
            'Compare with the same crop disease reference',
            'Confirm treatment with a farm specialist',
        ],
        'source': 'plantvillage-mobilenetv2',
        'model_id': MODEL_ID,
        'disclaimer': 'A pretrained PlantVillage classifier, not a diagnosis.',
    }


def yield_prediction(cycle):
    harvests = cycle.activities.filter(kind=Activity.Kind.HARVEST)
    total_kg = Decimal('0')
    for harvest in harvests:
        if harvest.quantity is None:
            continue
        if harvest.unit == 'kg':
            total_kg += harvest.quantity
        elif harvest.unit == 't':
            total_kg += harvest.quantity * 1000
    if total_kg:
        low = total_kg
        high = total_kg * Decimal('1.2')
    else:
        low = cycle.area * Decimal('4')
        high = cycle.area * Decimal('7')
    return {
        'cycle': cycle.pk,
        'crop': cycle.crop_type.name,
        'area': str(cycle.area),
        'estimated_production_kg': {
            'low': round(float(low), 2),
            'high': round(float(high), 2),
        },
        'expected_harvest_date': (
            cycle.planting_date + timedelta(days=120)
        ).isoformat(),
        'source': 'baseline',
        'disclaimer': '',
    }

