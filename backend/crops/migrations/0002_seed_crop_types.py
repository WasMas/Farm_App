from django.db import migrations


def seed(apps, schema_editor):
    crop_type = apps.get_model('crops', 'CropType')
    for name in ['Tomato', 'Wheat', 'Olive', 'Potato', 'Pepper', 'Barley']:
        crop_type.objects.get_or_create(name=name)


class Migration(migrations.Migration):
    dependencies = [('crops', '0001_initial')]
    operations = [migrations.RunPython(seed, migrations.RunPython.noop)]
