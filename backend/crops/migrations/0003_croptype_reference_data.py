from django.db import migrations, models


def seed_reference_data(apps, schema_editor):
    crop_type = apps.get_model('crops', 'CropType')
    defaults = {
        'tomato': (['sandy', 'loam'], {'flowering': 45, 'fruiting': 70, 'mature': 100, 'harvest': 110}),
        'pepper': (['loam', 'sandy'], {'flowering': 55, 'fruiting': 80, 'mature': 110, 'harvest': 120}),
        'potato': (['sandy', 'loam'], {'flowering': 50, 'mature': 90, 'harvest': 100}),
        'wheat': (['loam', 'clay', 'silt'], {'flowering': 75, 'mature': 120, 'harvest': 140}),
        'barley': (['loam', 'clay', 'silt'], {'flowering': 70, 'mature': 115, 'harvest': 130}),
        'olive': (['loam', 'sandy'], {'flowering': 180, 'mature': 240, 'harvest': 270}),
    }
    for crop in crop_type.objects.all():
        soils, stages = defaults.get(crop.name.casefold(), ([], {}))
        crop.suitable_soils = soils
        crop.stage_days = stages
        crop.save(update_fields=['suitable_soils', 'stage_days'])


class Migration(migrations.Migration):
    dependencies = [('crops', '0002_seed_crop_types')]
    operations = [
        migrations.AddField(
            model_name='croptype',
            name='stage_days',
            field=models.JSONField(blank=True, default=dict),
        ),
        migrations.AddField(
            model_name='croptype',
            name='suitable_soils',
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.RunPython(seed_reference_data, migrations.RunPython.noop),
    ]
