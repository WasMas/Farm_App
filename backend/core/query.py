from rest_framework.exceptions import ValidationError


def positive_id(value, label):
    try:
        parsed = int(value)
        if parsed < 1:
            raise ValueError
        return parsed
    except (ValueError, TypeError) as exc:
        raise ValidationError({label: 'Use a positive integer ID.'}) from exc
