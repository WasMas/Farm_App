"""Regression tests for selecting the Flutter build used by the passive demo."""
import io
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch

import demo
import passive_zap


class DemoWebBuildTests(unittest.TestCase):
    def test_web_build_requires_passive_zap(self):
        errors = io.StringIO()
        with patch('sys.argv', ['demo.py', '--web-build', 'site']), redirect_stderr(errors):
            with self.assertRaises(SystemExit) as exit_status:
                demo.main()
        self.assertEqual(exit_status.exception.code, 2)
        self.assertIn('--web-build requires --passive-zap', errors.getvalue())

    def test_cli_passes_the_selected_build_to_the_passive_demo(self):
        args = ['demo.py', '--passive-zap', 'zap.jar', '--web-build', 'site']
        db = {'DB_USER': 'test', 'DB_PASSWORD': 'test', 'DB_HOST': 'localhost', 'DB_PORT': '5432'}
        with (
            patch('sys.argv', args), patch.dict(demo.os.environ, db),
            patch.object(demo.psycopg, 'connect'), patch.object(demo.subprocess, 'run'),
            patch.object(passive_zap, 'observe') as observe,
        ):
            demo.main()
        observe.assert_called_once()
        jar, _, _, _, build = observe.call_args.args
        self.assertEqual((jar, build), ('zap.jar', Path('site')))

    def test_provided_build_requires_an_entry_point_and_skips_compilation(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(passive_zap.subprocess, 'run') as compile_web:
            root = Path(tmp)
            site = root / 'release'
            site.mkdir()
            jar = root / 'zap.jar'
            jar.touch()
            with self.assertRaisesRegex(ValueError, 'Missing Flutter web entry point'):
                passive_zap.observe(jar, [], {}, root, site)
            (site / 'index.html').write_text('<html></html>', encoding='utf-8')
            self.assertEqual(passive_zap.prepare_web_build(root, 'http://localhost', site), site.resolve())
            compile_web.assert_not_called()

    def test_local_build_targets_the_demo_api(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(passive_zap.subprocess, 'run') as compile_web:
            root = Path(tmp)
            api = 'http://127.0.0.1:18000'
            site = passive_zap.prepare_web_build(root, api, None)
            self.assertEqual(site, root / '.local/zap-web')
            compile_web.assert_called_once()
            command = compile_web.call_args.args[0]
            self.assertEqual(command[1:], ['build', 'web', '--release', '--no-web-resources-cdn',
                                           f'--output={site}', f'--dart-define=API_BASE_URL={api}/api/'])
            self.assertEqual(compile_web.call_args.kwargs, {'cwd': root / 'frontend', 'check': True})
