from datetime import timedelta

from django.db import connection
from django.utils import timezone


def summarize(farms):
    # Each aggregate is computed at its own grain. Joining all four tables
    # before summing would count a farm's area once for every activity.
    farm_ids = list(farms.values_list('pk', flat=True))
    start = timezone.localdate() - timedelta(days=6)
    with connection.cursor() as cursor:
        cursor.execute("""
            WITH fields AS (
                SELECT id FROM farms_field WHERE farm_id = ANY(%s)
            ), cycles AS (
                SELECT id, status FROM crops_cropcycle WHERE field_id IN (SELECT id FROM fields)
            )
            SELECT
                (SELECT COUNT(*) FROM fields) AS fields,
                (SELECT COUNT(*) FROM cycles WHERE status = 'active') AS active_cycles,
                (SELECT COALESCE(SUM(total_area), 0) FROM farms_farm WHERE id = ANY(%s)) AS total_area,
                COUNT(*) FILTER (WHERE date >= %s) AS activities_week,
                COALESCE(SUM(CASE unit WHEN 'l' THEN quantity / 1000
                                       WHEN 'm3' THEN quantity END)
                         FILTER (WHERE kind = 'irrigation' AND date >= %s), 0) AS irrigation_m3_week,
                COALESCE(SUM(CASE unit WHEN 't' THEN quantity * 1000
                                       WHEN 'kg' THEN quantity END)
                         FILTER (WHERE kind = 'harvest'), 0) AS harvest_kg,
                COALESCE(SUM(quantity) FILTER (WHERE kind = 'harvest' AND unit = 'items'), 0) AS harvest_items
            FROM activities_activity WHERE cycle_id IN (SELECT id FROM cycles)
        """, [farm_ids, farm_ids, start, start])
        summary = dict(zip((column.name for column in cursor.description), cursor.fetchone()))
    return {'farms': len(farm_ids), **summary}
