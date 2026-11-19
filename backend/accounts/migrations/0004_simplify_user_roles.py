from django.db import migrations, models


def simplify_roles(apps, schema_editor):
    User = apps.get_model('accounts', 'User')
    User.objects.filter(role='farmer').update(role='owner')
    User.objects.filter(role='expert').update(role='worker')


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0003_alter_user_role'),
    ]

    operations = [
        migrations.RunPython(simplify_roles, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='user',
            name='role',
            field=models.CharField(
                choices=[
                    ('admin', 'Administrator'),
                    ('owner', 'Farm owner'),
                    ('worker', 'Farm worker'),
                ],
                default='owner',
                max_length=12,
            ),
        ),
    ]
