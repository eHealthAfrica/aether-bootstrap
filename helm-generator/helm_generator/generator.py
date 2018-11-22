import helm_generator.args as args
import helm_generator.templateGenerator as templateGenerator
import helm_generator.secretsGenerator as secretsGenerator

arg_opts = args.arg_options()


def get_apps():
    """Get list of apps."""
    apps = ['kernel']
    modules = arg_opts['modules'].split(',')
    for module in modules:
        apps.append(module)
    if arg_opts['gather']:
        apps.append('gather')
    return apps


def create_value_override_file(app, modules):
    """Create override files."""
    templateGenerator.write_file(arg_opts, 'values',
                                 arg_opts['template_path'],
                                 app, modules)


def create_secrets_file(app):
    """Create secrets files."""
    secrets = secretsGenerator.generate_secrets(app,
                                                arg_opts['project'])
    templateGenerator.write_file(secrets, 'secrets',
                                 arg_opts['secrets_path'], app,
                                 modules=False)


def main():
    """Main."""
    apps = get_apps()
    modules = arg_opts['modules'].split(',')
    for app in apps:
        print('Creating Helm override for: {}'.format(app))
        create_value_override_file(app, modules)
        print('Creating secrets file for: {}'.format(app))
        create_secrets_file(app)

if __name__ == '__main__':
    main()
