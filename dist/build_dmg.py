#!/usr/bin/python
#
# Build distribution for Cameras
#

import sys, os, subprocess, time, shutil, plistlib
from optparse import OptionParser

# Read the options
parser = OptionParser()
parser.add_option('-n', '--name', dest='name', help='Full name or path of the product')
parser.add_option('-b', '--bgimage', dest='bgimage', help='Window background image', default='dist/bgimage.jpg')
parser.add_option('-p', '--icon-position', dest='icon_position', help='Icon position of build product', default='{365, 121}')
parser.add_option('-s', '--window-bounds', dest='window_bounds', help='Bounds of the Finder window', default='{100, 100, 600, 420}')

(options, args) = parser.parse_args()

build_dir = os.path.join(os.environ['BUILD_ROOT'], os.environ['BUILD_STYLE'])
product_path = os.path.join(build_dir, options.name)
info = plistlib.readPlist(os.path.join(product_path, 'Contents/Info.plist'))
product_name = info['CFBundleName']
product_version = info['CFBundleShortVersionString']

if not product_version:
    product_version = info['CFBundleVersion']

volume_name = product_name + ' ' + product_version

if os.environ['BUILD_STYLE'] == 'Release':
	final_dmg_path = os.path.join(build_dir, product_name + '_' + product_version + '.dmg')
else:
	#Add the build style to the volume if not release, as a precaution
	volume_name = volume_name + ' (' + os.environ['BUILD_STYLE'] + ')'
	final_dmg_path = os.path.join(build_dir, product_name + '_' + product_version + '_' + os.environ['BUILD_STYLE'] + '.dmg')

temp_dmg_path = os.path.join(build_dir, volume_name + '.dmg')
dmg_mount_path = os.path.join('/Volumes', volume_name)

# Create a disk image in the build folder
if os.path.exists(temp_dmg_path):
	os.remove(temp_dmg_path)

if os.path.exists(final_dmg_path):
	os.remove(final_dmg_path)

subprocess.call(['hdiutil', 'create', temp_dmg_path, '-size', '10m', '-fs', 'HFS+', '-volname', volume_name])
subprocess.call(['hdiutil', 'attach', temp_dmg_path])

# Can't use shutils copying because of resource forks and other metadata
subprocess.call(['cp', '-Rp', product_path, os.path.join(dmg_mount_path, os.path.basename(product_path))])

# Copy dmg background image if it exists and run Finder AppleScripts
if os.path.exists(options.bgimage):
    # Set the window background image
    os.mkdir(os.path.join(dmg_mount_path, '.invisible'))
    
    (bgimage, bgext) = os.path.splitext(options.bgimage)
    bgimage_path = os.path.join(dmg_mount_path, '.invisible/bg' + bgext)
    
    shutil.copy(options.bgimage, bgimage_path)
    
    set_bg_script = """osascript<<END
    tell application "Finder"
    open POSIX file "%s"
    set dmg_window to window "%s"
    set toolbar visible of dmg_window to false
    set statusbar visible of dmg_window to false
    set background picture of icon view options of dmg_window to POSIX file "%s"
    set icon size of icon view options of dmg_window to 84
    set position of file "%s" in dmg_window to %s
    set bounds of dmg_window to %s
    delay 1
    close dmg_window
    end tell
    """ % (dmg_mount_path, volume_name, bgimage_path, os.path.basename(product_path), options.icon_position, options.window_bounds)
else:
    set_bg_script = """osascript<<END
    tell application "Finder"
    open POSIX file "%s"
    set dmg_window to window "%s"
    set toolbar visible of dmg_window to false
    set statusbar visible of dmg_window to false
    set icon size of icon view options of dmg_window to 84
    set position of file "%s" in dmg_window to %s
    set bounds of dmg_window to %s
    delay 1
    close dmg_window
    end tell
    """ % (dmg_mount_path, volume_name, os.path.basename(product_path), options.icon_position, options.window_bounds)

os.system(set_bg_script)

open_folder_script = """osascript<<END
tell application "Finder"
open POSIX file "%s"
end tell
""" % (dmg_mount_path)

os.system(open_folder_script)

time.sleep(5)

# Unmount and convert dmg
subprocess.call(['hdiutil', 'detach', dmg_mount_path])
subprocess.call(['hdiutil', 'convert', temp_dmg_path, '-format', 'UDZO', '-o', final_dmg_path, '-imagekey', 'zlib-level=9'])

os.remove(temp_dmg_path)
