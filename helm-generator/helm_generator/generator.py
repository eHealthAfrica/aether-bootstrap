import helm_generator.args as args
import helm_generator.templateGenerator as templateGenerator
import helm_generator.secretsGenerator as secretsGenerator

arg_opts = args.arg_options()


def get_apps():
    """Get list of apps."""
    apps = ['kernel']
    modules = arg_opts['modules'].split(',')
    if 'kernel' in modules:
        modules.remove('kernel')
    for module in modules:
        apps.append(module)
    if 'enable_gather' in arg_opts:
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
                                 arg_opts['secrets_path'], app, modules=False)


def main():
    """Main."""
    apps = get_apps()
    if 'gather' in apps:
        modules = apps.remove('gather')
    else:
        modules = apps
    for app in apps:
        print('Creating Helm override for: {}'.format(app))
        create_value_override_file(app, modules)
        print('Creating secrets file for: {}'.format(app))
        create_secrets_file(app)

if __name__ == '__main__':
    main()
