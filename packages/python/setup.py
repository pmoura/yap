#!/usr/bin/env python
# coding: utf-8

# Copyright (c) IPython Development Team.
# Distributed under the terms of the Modified BSD License.

from __future__ import print_function

# the name of the package
name = 'yap_kernel'

#-----------------------------------------------------------------------------
# Minimal Python version sanity check
#-----------------------------------------------------------------------------

import sys

v = sys.version_info
if v[:2] < (2,7) or (v[0] >= 3 and v[:2] < (3,3)):
    error = "ERROR: %s requires Python version 2.7 or 3.3 or above." % name
    print(error, file=sys.stderr)
    sys.exit(1)

PY3 = (sys.version_info[0] >= 3)

#-----------------------------------------------------------------------------
# get on with it
#-----------------------------------------------------------------------------

from glob import glob
import os
import shutil

from distutils.core import setup

pjoin = os.path.join
here = os.path.abspath(os.path.dirname(__file__))
pkg_root = pjoin(here, name)

packages = []
for d, _, _ in os.walk(pjoin(here, name)):
    if os.path.exists(pjoin(d, '__init__.py')):
        packages.append(d[len(here)+1:].replace(os.path.sep, '.'))

package_data = {
    'ipykernel': ['resources/*.*'],
}

version_ns = {}
with open(pjoin(here, name, '_version.py')) as f:
    exec(f.read(), {}, version_ns)


setup_args = dict(
    name            = name,
    version         = version_ns['__version__'],
    scripts         = glob(pjoin('scripts', '*')),
    packages        = packages,
    py_modules      = ['ipykernel_launcher'],
    package_data    = package_data,
    description     = "IPython Kernel for Jupyter",
    author          = 'IPython Development Team',
    author_email    = 'ipython-dev@scipy.org',
    url             = 'http://ipython.org',
    license         = 'BSD',
    platforms       = "Linux, Mac OS X, Windows",
    keywords        = ['Interactive', 'Interpreter', 'Shell', 'Web'],
    classifiers     = [
        'Intended Audience :: Developers',
        'Intended Audience :: System Administrators',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
    ],
)

if 'develop' in sys.argv or any(a.startswith('bdist') for a in sys.argv):
    import setuptools

setuptools_args = {}
install_requires = setuptools_args['install_requires'] = [
    'ipython>=4.0.0',
    'traitlets>=4.1.0',
    'jupyter_client',
    'tornado>=4.0',
]

if any(a.startswith(('bdist', 'build', 'install')) for a in sys.argv):
    from ipykernel.kernelspec import write_kernel_spec, make_yap_kernel_cmd, KERNEL_NAME

    argv = make_yap_kernel_cmd(executable='python')
    dest = os.path.join(here, 'data_kernelspec')
    if os.path.exists(dest):
        shutil.rmtree(dest)
    write_kernel_spec(dest, overrides={'argv': argv})

    setup_args['data_files'] = [
        (pjoin('share', 'jupyter', 'kernels', KERNEL_NAME), glob(pjoin(dest, '*'))),
    ]

extras_require = setuptools_args['extras_require'] = {
    'test:python_version=="2.7"': ['mock'],
    'test': ['nose_warnings_filters', 'nose-timer'],
}

if 'setuptools' in sys.modules:
    setup_args.update(setuptools_args)

if __name__ == '__main__':
    setup(**setup_args)
