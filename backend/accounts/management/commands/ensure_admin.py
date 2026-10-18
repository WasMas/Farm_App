import os
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError
from django.db import connection, transaction
from django.db.models import Q
from accounts.models import User


class Command(BaseCommand):
    help = 'Create the initial administrator from environment variables only when no active administrator exists.'

    @transaction.atomic
    def handle(self, *args, **options):
        # Serialize concurrent startup commands without maintaining another table.
        with connection.cursor() as cursor:
            cursor.execute('SELECT pg_advisory_xact_lock(%s)', [914232107])
        if User.objects.filter(is_active=True).filter(Q(is_superuser=True) | Q(is_staff=True)).exists():
            self.stdout.write('An active administrator already exists; nothing changed.')
            return
        username = os.getenv('INITIAL_ADMIN_USERNAME', '').strip()
        email = os.getenv('INITIAL_ADMIN_EMAIL', '').strip()
        password = os.getenv('INITIAL_ADMIN_PASSWORD', '')
        if not all([username, email, password]):
            raise CommandError('Set INITIAL_ADMIN_USERNAME, INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD in .env.')
        if User.objects.filter(Q(username=username) | Q(email=email)).exists():
            raise CommandError('The configured identity already belongs to an account. Choose another initial admin identity.')
        try:
            validate_password(password, User(username=username, email=email))
        except ValidationError as exc:
            raise CommandError('; '.join(exc.messages)) from exc
        User.objects.create_superuser(username=username, email=email, password=password, role=User.Role.ADMIN)
        self.stdout.write(self.style.SUCCESS('Initial administrator created. Credentials remain in your local .env.'))
