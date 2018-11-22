#!/usr/bin/env python3

import argparse


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
        ['-g', '--gather', 'enable Gather, expects True or False', False],
        ['--cm', '--cert-manager', 'Using cert manager?', False],
        ['-m', '--modules', 'Aether modules i.e kernel,odk,ui', False]
    ]
    return arg_list


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
    return arg_dict

if __name__ == '__main__':
    arg_options()
