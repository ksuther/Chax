#!/usr/bin/python
#
# Code signing for ksuther.com apps
#

import sys, os, subprocess, plistlib, string

info = plistlib.readPlist(os.path.join(os.environ['BUILT_PRODUCTS_DIR'], os.environ['INFOPLIST_PATH']))
version = info['CFBundleVersion']
is_alpha = string.find(version, 'a') > -1
is_beta = string.find(version, 'b') > -1

if os.environ['BUILD_STYLE'] == 'Release' and not is_alpha and not is_beta:
	for i in range(1, len(sys.argv)):
		subprocess.call(['codesign', '-f', '-v', '-s', 'ksuther.com', sys.argv[i]])
else:
	print os.path.basename(sys.argv[0]) + ': Skipping code signing for non-release version'