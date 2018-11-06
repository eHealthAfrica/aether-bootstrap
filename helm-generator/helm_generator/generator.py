#!/usr/bin/env python3

import helm_generator.args as args
import helm_generator.templateGenerator as templateGenerator
import helm_generator.secretsGenerator as secretsGenerator

arg_opts = args.arg_options()


def create_value_override_file():
    """Create override files."""
    aether_modules = arg_opts['am'].split(',')
    arg_opts['aether_modules'] = aether_modules
    templateGenerator.write_file(arg_opts, 'values',
                                 arg_opts['template_path'])


def create_secrets_file():
    """Create secrets files."""
    secrets = secretsGenerator.generate_secrets(arg_opts['application'],
                                                arg_opts['project'])
    templateGenerator.write_file(secrets, 'secrets',
                                 arg_opts['secrets_path'])


def main():
    """Main."""
    print('Creating Helm override')
    create_value_override_file()
    print('Creating secrets file')
    create_secrets_file()

if __name__ == '__main__':
    main()
