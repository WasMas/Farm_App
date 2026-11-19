from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import User
from recommendations.services import generate_recommendations


class Command(BaseCommand):
    help = 'Create pending crop recommendations for all farm owners.'

    def add_arguments(self, parser):
        parser.add_argument('--as-of', dest='as_of')
        parser.add_argument('--use-ai', action='store_true')

    def handle(self, *args, **options):
        as_of = timezone.localdate()
        if options['as_of']:
            as_of = timezone.datetime.strptime(options['as_of'], '%Y-%m-%d').date()
        total = 0
        for owner in User.objects.filter(
            is_active=True,
            role=User.Role.OWNER,
        ):
            total += len(
                generate_recommendations(owner, as_of, use_ai=options['use_ai'])
            )
        self.stdout.write(self.style.SUCCESS(f'Created {total} recommendations.'))
