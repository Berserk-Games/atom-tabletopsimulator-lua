import sys, subprocess, re

version = sys.argv[1]
if not re.match("[0-9]+\.[0-9]+\.[0-9]", version):
    print "Version must be of the form: 10.8.1"
    sys.exit(1)

def confirm(msg):
    print msg, "(<Enter> to continue, <CTRL-BREAK> to exit)"
    raw_input()

version = "v" + version
print "Version:", version

confirm("Update this repository:")
output = subprocess.check_output(['git.exe', 'pull', 'origin', 'master'], stderr=subprocess.STDOUT)
print output

confirm("Tag this repository:")
output = subprocess.check_output(['git.exe', 'tag', '-a', version, '-m', '"%s"' % version], stderr=subprocess.STDOUT)
print output

confirm("Push tag to online repository:")
output = subprocess.check_output(['git.exe', 'push', 'origin', version], stderr=subprocess.STDOUT)
print output

confirm("Publish Atom package:")
output = subprocess.check_output(['apm', 'publish', '--tag', version], stderr=subprocess.STDOUT, shell=True)
print output
