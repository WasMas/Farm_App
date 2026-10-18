"""Discover Django tests from the backend project, even when called at repository root."""
import subprocess
import sys
from pathlib import Path

subprocess.run([sys.executable, 'manage.py', 'test', '--noinput', *sys.argv[1:]],
               cwd=Path(__file__).resolve().parent.parent / 'backend', check=True)
