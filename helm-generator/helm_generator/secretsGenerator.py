#!/usr/bin/env python3

import secrets
import base64


def generate_encoded_secret():
    """Generate secure token."""
    secret = secrets.token_urlsafe(nbytes=36).encode()
    encoded_secret = base64.b64encode(secret)
    return(encoded_secret)


def generate_secrets(application):
    """Generate secrets."""
    secrets_dict = {}
    secrets_list = [
        'admin_token',
        'secret_key',
        'admin_password',
        'database_password',
        'readonly_db_password'
    ]
    for secret in secrets_list:
        secrets_dict[secret] = generate_encoded_secret()
    secrets_dict['application'] = application
    return secrets_dict
