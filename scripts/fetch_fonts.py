"""Download the project's OFL-licensed typography from the Google Fonts source."""
from pathlib import Path
from urllib.request import urlopen

target = Path(__file__).resolve().parent.parent / 'frontend/assets/fonts'
target.mkdir(parents=True, exist_ok=True)
sources = {
    'Lora.ttf': 'ofl/lora/Lora%5Bwght%5D.ttf', 'Lora-OFL.txt': 'ofl/lora/OFL.txt',
    'DMSans.ttf': 'ofl/dmsans/DMSans%5Bopsz,wght%5D.ttf', 'DMSans-OFL.txt': 'ofl/dmsans/OFL.txt',
}
for name, source in sources.items():
    with urlopen('https://raw.githubusercontent.com/google/fonts/main/' + source, timeout=30) as response:
        data = response.read()
    if name.endswith('.ttf') and data[:4] not in [b'\x00\x01\x00\x00', b'OTTO']:
        raise ValueError('Unexpected font format')
    (target / name).write_bytes(data)
    print(f'Downloaded {name}')
