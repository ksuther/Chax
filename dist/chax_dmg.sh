#!/bin/bash
#
# DMG creation script for Chax
#

VERSION=`defaults read $PROJECT_DIR/ChaxAddition-Info CFBundleShortVersionString`
NAME="Chax $VERSION"
FINAL_NAME="Chax_$VERSION"
BUILD_DIR=$BUILD_ROOT/$BUILD_STYLE

#IS_BETA="no"
#[[ "$VERSION" =~ "b" ]] && IS_BETA="beta"

rm -f "$BUILD_DIR/$NAME.dmg"

hdiutil create "$BUILD_DIR/$NAME.dmg" -size 05m -fs HFS+ -volname "$NAME"
hdiutil attach "$BUILD_DIR/$NAME.dmg"

ditto -rsrcFork "$BUILD_DIR/Chax Installer.app" "/Volumes/$NAME/Chax $VERSION Installer.app"

hdiutil detach "/Volumes/$NAME"
hdiutil convert "$BUILD_DIR/$NAME.dmg" -format UDZO -o "$BUILD_DIR/$NAME.udzo.dmg" -imagekey zlib-level=9

rm -f "$BUILD_DIR/$NAME.dmg"
hdiutil internet-enable -yes "$BUILD_DIR/$NAME.udzo.dmg"
mv "$BUILD_DIR/$NAME.udzo.dmg" "$BUILD_DIR/$FINAL_NAME.dmg"

#Upload the file
#osascript /Users/kent/Programming/Chax/Release/upload_dmg.scpt $IS_BETA /Users/kent/Sites/chax/downloads/beta/$FINAL_NAME.dmg