"""Launch a seeded, disposable Fieldbook demo on localhost. Ctrl+C ends the demo."""
import argparse
import os
import secrets
import subprocess
import sys
from pathlib import Path
from uuid import uuid4

import psycopg
from dotenv import load_dotenv
from psycopg import sql


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify the seeded demo and exit.')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    load_dotenv(root / 'backend' / '.env')
    database = 'fieldbook_demo_' + uuid4().hex
    password = secrets.token_urlsafe(12)
    env = dict(os.environ, DB_NAME=database, DB_POOL='1', DJANGO_DEBUG='True',
               CORS_ALLOWED_ORIGINS='http://localhost:8080',
               INITIAL_ADMIN_USERNAME='demo_admin', INITIAL_ADMIN_EMAIL='admin@example.invalid',
               INITIAL_ADMIN_PASSWORD=password)
    manage = [sys.executable, str(root / 'backend' / 'manage.py')]
    with psycopg.connect(dbname='postgres', user=os.environ['DB_USER'],
                         password=os.environ['DB_PASSWORD'], host=os.environ['DB_HOST'],
                         port=os.environ['DB_PORT'], autocommit=True) as connection:
        name = sql.Identifier(database)
        connection.execute(sql.SQL('CREATE DATABASE {}').format(name))
        try:
            for command in [('migrate', '--noinput'), ('ensure_admin',), ('seed_demo', '--reset')]:
                subprocess.run(manage + list(command), env=env, check=True)
            if args.check:
                check = ("from accounts.models import User; from farms.models import Farm; "
                         "from activities.models import Activity; "
                         "assert User.objects.get(username='demo_owner').check_password('FieldbookDemo123!'); "
                         "assert Farm.objects.exists() and Activity.objects.exists(); "
                         "print('Demo owner login, farms and activity fixtures verified.')")
                subprocess.run(manage + ['shell', '-c', check], env=env, check=True)
                return
            print(f'Demo admin: demo_admin / {password}', flush=True)
            subprocess.run(manage + ['runserver', '127.0.0.1:8000', '--noreload'], env=env, check=True)
        except KeyboardInterrupt:
            pass
        finally:
            connection.execute(sql.SQL('DROP DATABASE {} WITH (FORCE)').format(name))


if __name__ == '__main__':
    main()

