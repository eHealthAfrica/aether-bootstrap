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
    template = env.get_template('{}.tmpl.yaml'.format(f_type))
    template = template.render(arg_opts=arg_opts)
    return template


def write_file(arg_opts, f_type, dir_path):
    """Write out YAML."""
    output = render_template(arg_opts, f_type)
    path = os.path.join(check_dir(dir_path),
                        '{}.yaml').format(f_type)

    with open(path, 'w') as file:
        file.write(output)
