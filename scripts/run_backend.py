"""Migrate and ensure an administrator on every normal local startup."""
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
manage = str(root / 'backend' / 'manage.py')
for arguments in [('migrate', '--noinput'), ('ensure_admin',), ('runserver', *sys.argv[1:])]:
    subprocess.run([sys.executable, manage, *arguments], check=True, cwd=root)
