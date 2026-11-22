"""Check every hosted package locked by Flutter against the OSV Pub database."""
import json
from pathlib import Path
from urllib.request import Request, urlopen

import yaml


def main():
    packages = yaml.safe_load(Path('frontend/pubspec.lock').read_text())['packages']
    queries = [
        {'package': {'ecosystem': 'Pub', 'name': name}, 'version': entry['version']}
        for name, entry in packages.items() if entry['source'] == 'hosted'
    ]
    if not queries:
        raise ValueError('No hosted Dart packages found in pubspec.lock')
    request = Request('https://api.osv.dev/v1/querybatch', json.dumps({'queries': queries}).encode(),
                      headers={'Content-Type': 'application/json'})
    with urlopen(request, timeout=60) as response:
        results = json.load(response)['results']
    if len(results) != len(queries):
        raise ValueError('Incomplete OSV results')
    findings = []
    for query, result in zip(queries, results):
        for vulnerability in result.get('vulns', []):
            findings.append({**query, 'advisory': vulnerability['id']})
    print(json.dumps({'hosted_packages_checked': len(queries), 'findings': findings}, indent=2))
    return bool(findings)


if __name__ == '__main__':
    raise SystemExit(main())
