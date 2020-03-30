import argparse
import sys


def arg_list():
    """Arg in a dict."""
    arg_list = [
        ['-d', '--domain', 'Specify the domain you are using'],
        ['-t', '--template-path', 'Specify template path'],
        ['-s', '--secrets-path', 'Specify template path'],
        ['-p', '--project', 'Specify a project name'],
        ['-c', '--cloud-platform', 'Specify the platform used'],
        ['-so', '--secrets-only', 'Generate secrets only'],
        ['-db', '--database-host', 'Specify the database host'],
        ['-dbc', '--database-connection-name', 'Specify the database connection name (GCP)'],
        ['-sbn', '--storage-bucket-name', 'Specify storage bucket name'],
        ['-sb', '--storage-backend', 'Specify storage backend s3/gcp/filesystem'],
        ['--acm', '--aws-cert-arn', 'Specify AWS ACM'],
        ['--sg-id', '--aws-alg-sg-id', 'Specify AWS SG ID'],
        ['--sentry', '--senty-dsn', 'Specify Sentry DSN'],
        ['-e', '--environment', 'Specify environment'],
        ['-g', '--gather', 'enable Gather yes or no'],
        ['--cm', '--cert-manager', 'Using cert manager?'],
        ['-m', '--modules', 'Aether modules i.e odk,kernel-ui'],
        ['-r', '--redis-url', 'Redis endpoint'],
    ]
    return arg_list


def test_args(args):
    """Test Argparse options."""
    backend = args['storage_backend']
    modules = args['modules'].split(',')
    if not args['secrets_only']:
        if backend == 'gcp' or 's3':
            if 'storage_bucket_name' not in args:
                print('ERROR: Please set the bucket storage name')
                sys.exit(2)
        if not 'gcp' or 'aws' in args['cloud_platform']:
            print('Please specify AWS or GCP for --cloud-platform')
            sys.exit(2)


def test_module_names(modules):
    """Test module name."""
    valid_modules = ['kernel-ui', 'kernel', 'odk']
    for module in modules:
        if module not in valid_modules:
            print('{} is not a valid Aether module'.format(module))
            print('Valid options are {}'.format(str(valid_modules)))


def arg_options():
    """Argparse options."""
    parser = argparse.ArgumentParser()
    args = arg_list()
    for arg in args:
        parser.add_argument(arg[0], arg[1],
                            help=arg[2])
    parsed_args = parser.parse_args(args=None, namespace=None)
    arg_dict = vars(parsed_args)
    test_args(arg_dict)
    if arg_dict['modules']:
        modules = arg_dict['modules'].split(',')
        test_module_names(modules)
    return arg_dict


if __name__ == '__main__':
    arg_options()
