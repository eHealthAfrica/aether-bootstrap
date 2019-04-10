#!/usr/bin/env python3


import helm_generator.args as args
import helm_generator.templateGenerator as templateGenerator
import helm_generator.secretsGenerator as secretsGenerator
import sys

arg_opts = args.arg_options()


def test_args(*args):
    """Test args"""
    arg_list = list(args)
    for arg in arg_list:
        if not arg_opts[arg]:
            print('ERROR Please specify: --{} option'.format(arg))
            sys.exit(2)


def get_apps():
    """Get list of apps."""
    apps = ['kernel']
    modules = arg_opts['modules'].split(',')
    for module in modules:
        apps.append(module)
    if arg_opts['gather']:
        apps.append('gather')
    return apps


def get_modules():
    """Get modules."""
    modules = arg_opts['modules'].split(',')
    modules.append('kernel')
    return modules


def create_value_override_file(app, modules):
    """Create override files."""
    print('Creating Helm override for: {}'.format(app))
    templateGenerator.write_file(arg_opts, 'values',
                                 arg_opts['template_path'],
                                 app, modules)


def create_secrets_file(app):
    """Create secrets files."""
    test_args('project', 'secrets_path')
    project = arg_opts['project']
    print('Creating secrets file for: {}'.format(app))
    secrets = secretsGenerator.generate_secrets(app,
                                                project)
    templateGenerator.write_file(secrets, 'secrets',
                                 arg_opts['secrets_path'], app,
                                 modules=False)


def main():
    """Main."""
    apps = get_apps()
    modules = get_modules()
    for app in apps:
        if arg_opts['secrets_only']:
            create_secrets_file(app)
        else:
            create_value_override_file(app, modules)
            create_secrets_file(app)

if __name__ == '__main__':
    main()
