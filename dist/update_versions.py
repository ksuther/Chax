#!/usr/bin/python
#
# Update versions for all the Chax plists (bundle version and short version)
#

import sys, os, subprocess, time, shutil, plistlib

bundle_version = os.environ['CHAX_BUNDLE_VERSION']
short_version = os.environ['CHAX_SHORT_VERSION']

plists = ['ChaxHelperApp-Info.plist', 'ChaxAddition-Info.plist', 'ChaxLib-Info.plist', 'ChaxAgentLib-Info.plist', 'ChaxInstaller-Info.plist']

for plist in plists:
    plist_path = os.path.join(os.environ['PROJECT_DIR'], plist)
    plist_object = plistlib.readPlist(plist_path)
    
    plist_object['CFBundleVersion'] = bundle_version
    plist_object['CFBundleShortVersionString'] = short_version
    
    plistlib.writePlist(plist_object, plist_path)