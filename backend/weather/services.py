import base64
import hashlib
import json
import math
from datetime import timedelta
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from urllib.error import URLError

from cryptography.fernet import Fernet, InvalidToken
from django.conf import settings
from django.utils import timezone
from .models import WeatherSnapshot

VARIABLES = {'temperature': 'temperature_2m', 'humidity': 'relative_humidity_2m', 'precipitation': 'precipitation', 'wind': 'wind_speed_10m'}


def cipher():
    return Fernet(base64.urlsafe_b64encode(hashlib.sha256(settings.SECRET_KEY.encode()).digest()))


def encrypt_key(key):
    return cipher().encrypt(key.encode()).decode() if key else ''


def decrypt_key(value):
    try:
        return cipher().decrypt(value.encode()).decode() if value else ''
    except InvalidToken:
        return ''


def missing(status, message):
    return {'status': status, 'message': message, 'current': dict.fromkeys(VARIABLES), 'forecast': [],
            'observed_at': None, 'retrieved_at': None, 'cached': False, 'source': 'Open-Meteo'}


def number(value):
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) else None


def weather_for(farm, config, force=False):
    if not config.enabled:
        return missing('not_configured', 'Connect weather to see conditions for your farm.')
    if farm.latitude is None or farm.longitude is None:
        return missing('not_configured', 'Add latitude and longitude to this farm first.')
    key = decrypt_key(config.encrypted_key)
    if config.mode == 'customer' and not key:
        return missing('not_configured', 'Add your Open-Meteo customer key, or choose the public API.')
    snapshot = WeatherSnapshot.objects.filter(user=config.user, farm=farm, latitude=farm.latitude,
        longitude=farm.longitude, retrieved_at__gte=timezone.now() - timedelta(minutes=10)).first()
    if snapshot and not force:
        return {**snapshot.payload, 'cached': True}
    params = {'latitude': str(farm.latitude), 'longitude': str(farm.longitude), 'current': ','.join(VARIABLES.values()),
              'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum', 'forecast_days': 5, 'timezone': 'auto'}
    host = 'https://customer-api.open-meteo.com' if config.mode == 'customer' else 'https://api.open-meteo.com'
    if config.mode == 'customer':
        params['apikey'] = key
    try:
        request = Request(f'{host}/v1/forecast?{urlencode(params)}', headers={'User-Agent': 'Fieldbook/1.0'})
        with urlopen(request, timeout=7) as response:
            data = json.loads(response.read(1_000_000))
        current = data.get('current', {})
        values = {name: number(current.get(variable)) for name, variable in VARIABLES.items()}
        if not any(value is not None for value in values.values()):
            raise ValueError('Missing current weather')
        daily = data.get('daily', {})
        forecast = []
        for i, day in enumerate(daily.get('time', [])[:5]):
            def at(key):
                items = daily.get(key, [])
                return number(items[i]) if i < len(items) else None
            forecast.append({'date': day, 'high': at('temperature_2m_max'), 'low': at('temperature_2m_min'), 'rain': at('precipitation_sum')})
        observed_at = current.get('time')
        if observed_at:
            # Open-Meteo ISO times are local to the response's fixed UTC offset.
            from datetime import datetime, timezone as dt_timezone
            observed_at = datetime.fromisoformat(observed_at).replace(tzinfo=dt_timezone(timedelta(seconds=int(data.get('utc_offset_seconds', 0))))).isoformat()
        payload = {'status': 'ok', 'message': 'Current modelled conditions', 'current': values, 'forecast': forecast,
                   'observed_at': observed_at, 'retrieved_at': timezone.now().isoformat(), 'cached': False, 'source': 'Open-Meteo'}
        WeatherSnapshot.objects.update_or_create(user=config.user, farm=farm, defaults={'latitude': farm.latitude, 'longitude': farm.longitude, 'payload': payload})
        return payload
    except (URLError, OSError, ValueError, TypeError, KeyError, AttributeError, OverflowError):
        # Never return an exception URL: it may contain a customer credential.
        return missing('unavailable', 'Weather is unavailable right now. Try again in a moment.')
