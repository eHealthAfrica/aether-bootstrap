#!/usr/bin/env python3

from setuptools import setup


setup(name='aether-helm-generator',
      version='1.3',
      description='Generate values and secrets for Helm',
      url='http://github.com/ehealthafrica/aether-bootstrap',
      author='Will Pink',
      author_email='devops@ehealthafrica.org',
      license='MIT',
      install_requires=['jinja2'],
      packages=['helm_generator'],
      package_data={'': ['templates/*.tmpl.yaml']},
      entry_points={
             'console_scripts':
             ['aether-helm-generator=helm_generator.generator:main'],
      },
      zip_safe=False)
