#!/usr/bin/env python3

import secrets


def generate_secret():
    """Generate secure token."""
    secret = secrets.token_urlsafe(nbytes=36)
    return(secret)


def generate_secrets(application):
    """Generate secrets."""
    secrets_dict = {}
    secrets_list = [
        'admin_token',
        'secret_key',
        'admin_password',
        'database_password'
    ]
    for secret in secrets_list:
        secrets_dict[secret] = generate_secret()
    secrets_dict['application'] = application
    return secrets_dict
