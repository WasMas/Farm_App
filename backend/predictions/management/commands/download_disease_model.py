from django.core.management.base import BaseCommand

from predictions.services import get_disease_model, MODEL_ID


class Command(BaseCommand):
    help = 'Download and verify the pretrained PlantVillage disease model.'

    def handle(self, *args, **options):
        processor, model = get_disease_model()
        if len(model.config.id2label) != 38:
            raise RuntimeError('Unexpected disease model class count.')
        self.stdout.write(
            self.style.SUCCESS(
                f'Downloaded {MODEL_ID}; verified {len(model.config.id2label)} classes.'
            )
        )
