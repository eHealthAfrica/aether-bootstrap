import argparse
import sys


def arg_list():
    """Arg in a dict."""
    arg_list = [
        ['-d', '--domain', 'Specify the domain you are using', True],
        ['-t', '--template-path', 'Specify template path', True],
        ['-s', '--secrets-path', 'Specify template path', True],
        ['-p', '--project', 'Specify a project name', True],
        ['-c', '--cloud-platform', 'Specify the platform used', True],
        ['-db', '--database-host', 'Specify the database host', True],
        ['-sbn', '--storage-bucket-name', 'Specify storage bucket name', False],
        ['-sb', '--storage-backend', 'Specify storage backend s3/gcp/filesystem', True],
        ['--acm', '--aws-cert-arn', 'Specify AWS ACM', False],
        ['--sg-id', '--aws-alg-sg-id', 'Specify AWS SG ID', False],
        ['--sentry', '--senty-dsn', 'Specify Sentry DSN', False],
        ['-e', '--environment', 'Specify environment', True],
        ['-g', '--gather', 'enable Gather yes or no', False],
        ['--cm', '--cert-manager', 'Using cert manager?', False],
        ['-m', '--modules', 'Aether modules i.e odk,ui,sync', False]
    ]
    return arg_list


def test_args(args):
    """Test Argparse options."""
    backend = args['storage_backend']
    if backend == 'gcp' or 's3':
        if 'storage_bucket_name' not in args:
            print('ERROR: Please set the bucket storage name')
            sys.exit(2)
    if not 'gcp' or 'aws' in args['cloud_platform']:
        print('Please specify AWS or GCP for --cloud-platform')
        sys.exit(2)


def arg_options():
    """Argparse options."""
    parser = argparse.ArgumentParser()
    args = arg_list()
    for arg in args:
        parser.add_argument(arg[0], arg[1],
                            help=arg[2],
                            required=arg[3])
    parsed_args = parser.parse_args(args=None, namespace=None)
    arg_dict = vars(parsed_args)
    test_args(arg_dict)
    return arg_dict

if __name__ == '__main__':
    arg_options()
