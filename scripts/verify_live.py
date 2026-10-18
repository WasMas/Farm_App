"""Run Flutter HTTP integration tests against an isolated, real PostgreSQL database."""
import os
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

import psycopg
from psycopg import sql
from dotenv import dotenv_values

root = Path(__file__).resolve().parent.parent
config = dotenv_values(root / 'backend' / '.env')
database = f'test_fieldbook_live_{os.getpid()}'
env = dict(os.environ, DB_NAME=database)
with socket.socket() as listener:
    listener.bind(('127.0.0.1', 0))
    port = listener.getsockname()[1]
server = None
dart = Path(os.getenv('FLUTTER_ROOT', 'C:/Portable/Develop/Flutter-3.47.6')) / 'bin/cache/dart-sdk/bin/dart.exe'
tool = dart.parents[2] / 'flutter_tools.snapshot'
with psycopg.connect(dbname='postgres', user=config['DB_USER'], password=config['DB_PASSWORD'],
                     host=config['DB_HOST'], port=config['DB_PORT'], autocommit=True) as connection:
    connection.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(database)))
    try:
        subprocess.run([sys.executable, str(root / 'backend/manage.py'), 'migrate', '--noinput'], env=env, check=True, stdout=subprocess.DEVNULL)
        server = subprocess.Popen([sys.executable, str(root / 'backend/manage.py'), 'runserver', f'127.0.0.1:{port}', '--noreload'], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(100):
            try:
                urllib.request.urlopen(f'http://127.0.0.1:{port}/api/health/', timeout=1).close()
                break
            except OSError:
                if server.poll() is not None:
                    raise RuntimeError('Integration server exited before startup')
                time.sleep(.1)
        else:
            raise RuntimeError('Integration server did not become ready')
        tests = sys.argv[1:] or ['test/live_api_test.dart', 'test/live_auth_test.dart']
        subprocess.run([str(dart), str(tool), 'test', '--no-pub', '--dart-define=RUN_LIVE_API_TESTS=true',
                        f'--dart-define=API_BASE_URL=http://127.0.0.1:{port}/api/', *tests], cwd=root / 'frontend', check=True)
    finally:
        if server:
            server.terminate()
            server.wait(timeout=15)
        connection.execute(sql.SQL('DROP DATABASE {} WITH (FORCE)').format(sql.Identifier(database)))
