import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        ('crops', '0003_croptype_reference_data'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='PredictionRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('kind', models.CharField(choices=[('disease', 'Disease'), ('yield', 'Yield')], max_length=12)),
                ('result', models.JSONField()),
                ('image', models.ImageField(blank=True, null=True, upload_to='prediction_images/%Y/%m/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('cycle', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='prediction_records', to='crops.cropcycle')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='prediction_records', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
