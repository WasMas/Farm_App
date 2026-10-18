"""Create ignored local credentials and the PostgreSQL database, without overwriting either."""
import secrets
from pathlib import Path

import psycopg
from psycopg import sql
from dotenv import dotenv_values

root = Path(__file__).resolve().parent.parent
env_path = root / 'backend' / '.env'
if not env_path.exists():
    values = (root / 'backend' / '.env.example').read_text()
    values = values.replace('DJANGO_SECRET_KEY=\n', f'DJANGO_SECRET_KEY={secrets.token_urlsafe(64)}\n')
    values = values.replace('INITIAL_ADMIN_PASSWORD=\n', f'INITIAL_ADMIN_PASSWORD={secrets.token_urlsafe(18)}\n')
    env_path.write_text(values)
env = dotenv_values(env_path)
with psycopg.connect(dbname='postgres', user=env['DB_USER'], password=env['DB_PASSWORD'],
                     host=env['DB_HOST'], port=env['DB_PORT'], autocommit=True) as conn:
    exists = conn.execute('SELECT 1 FROM pg_database WHERE datname=%s', (env['DB_NAME'],)).fetchone()
    if not exists:
        conn.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(env['DB_NAME'])))
print('Local environment and PostgreSQL database are ready. No credentials were printed.')
