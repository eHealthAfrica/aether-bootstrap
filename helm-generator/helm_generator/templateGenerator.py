#!/usr/bin/env python3

from jinja2 import Environment, FileSystemLoader
import os
import sys


def check_dir(dir_path):
    """Get directory path to overrides."""
    dir = dir_path
    if dir == '.':
        dir = os.getcwd()
    if not os.path.exists(dir):
        print("directory does not exist, exiting")
        os._exit(1)
    return dir


def render_template(arg_opts, f_type):
    """Template loader."""
    for path in sys.path:
        if os.path.isdir(os.path.join(path, 'helm_generator', 'templates')):
            path = os.path.join(path, 'helm_generator', 'templates')
    env = Environment(loader=FileSystemLoader(path),
                      trim_blocks=True,
                      lstrip_blocks=True)
    if f_type == 'values':
        postgres_ident = '{}_{}'.format(arg_opts['application'], arg_opts['project'])
        arg_opts['pg_name'] = postgres_ident.replace("-", "_")
    template = env.get_template('{}.tmpl.yaml'.format(f_type))
    rendered_template = template.render(arg_opts=arg_opts)
    return rendered_template


def write_file(arg_opts, f_type, dir_path):
    """Write out YAML."""
    output = render_template(arg_opts, f_type)
    filename = arg_opts['application']
    if f_type == 'secrets':
        filename = '{}-secrets'.format(arg_opts['application'])
    path = os.path.join(check_dir(dir_path),
                        '{}.yaml').format(filename)
    with open(path, 'w') as file:
        file.write(output)
