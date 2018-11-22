import secrets
import base64


def generate_encoded_secret():
    """Generate secure token."""
    generated_secret = secrets.token_hex(18).encode()
    encoded_secret = base64.b64encode(generated_secret)
    secret = encoded_secret.decode("utf-8")
    return secret


def generate_secrets(app, project):
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
    secrets_dict['project'] = project
    return secrets_dict
