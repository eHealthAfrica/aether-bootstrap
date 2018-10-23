#!/usr/bin/env python3

import secrets
import base64


def generate_encoded_secret():
    """Generate secure token."""
    generated_secret = secrets.token_hex(36).encode()
    encoded_secret = base64.b64encode(generated_secret)
    secret = encoded_secret.decode("utf-8")
    return(secret)


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
        print(secrets_dict[secret])
    secrets_dict['application'] = application
    return secrets_dict
