#!/usr/bin/env python3

from setuptools import setup


setup(name='aether-helm-generator',
      version='0.1',
      description='Generate values and secrets for Helm',
      url='http://github.com/ehealthafrica/aether-bootstrap',
      author='Will Pink',
      author_email='devops@ehealthafrica.org',
      license='MIT',
      install_requires=['jinja2'],
      packages=['helm_generator'],
      data_files=[('aether_helm_generator/templates',
                  ['templates/secrets.tmpl.yaml',
                   'templates/values.tmpl.yaml'])],
      include_package_data=True,
      entry_points={
             'console_scripts':
             ['aether-helm-generator=helm_generator.generator:main'],
      },
      zip_safe=False)
