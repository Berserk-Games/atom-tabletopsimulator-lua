#!/usr/bin/python

import sys, subprocess, re

msg = 'Version must be of the form: 10.8.1'

if len(sys.argv) < 2:
    print(msg)
    sys.exit(1)

version = sys.argv[1]
if version.lower()[0] == 'v':
    version = version[1:]
if not re.match(r'[0-9]+\.[0-9]+\.[0-9]', version):
    print(msg)
    sys.exit(1)


def confirm(command, shell=False):
    print(command + ' [<Enter> to continue, <CTRL-BREAK> to exit]')
    input()
    output = subprocess.check_output(command.split(), stderr=subprocess.STDOUT, shell=shell)
    if output.replace('\n', '').strip() == "":
        print('\033[1;32mOK\033[0;0m')
    else:
        print(output)
    if not output.endswith('\n'):
        print('')


version = "v" + version
print('')
print('Version: \033[1;33m' + version + '\033[0;0m')
print('')

confirm('git pull origin master')
confirm('git tag -a %s -m "%s"' % (version, version))
confirm('git push origin %s' % version)
confirm("apm publish --tag %s" % version, True)
