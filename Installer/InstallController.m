/*
 * InstallController.m
 *
 * Copyright (c) 2007-2010 Kent Sutherland
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "InstallController.h"
#import "SystemEvents.h"

#define DONATE_URL [NSURL URLWithString:@"http://www.ksuther.com/chax/donate"]
#define FAQ_URL [NSURL URLWithString:@"http://www.ksuther.com/chax/faq"]

#define SCRIPTING_ADDITIONS_PATH [@"~/Library/ScriptingAdditions" stringByExpandingTildeInPath]
#define SCRIPTING_ADDITIONS_OLD_PATH [@"~/Library/ScriptingAdditionsOld" stringByExpandingTildeInPath]

NSString *ChaxAdditionFilename = @"ChaxAddition.osax";

@interface InstallController ()
- (BOOL)_createScriptingAdditionsDirectory;
- (BOOL)_isInstalled;
- (void)_quitChaxHelperApp;
@end


@implementation InstallController

- (void)awakeFromNib
{
    [_window center];
    
    [self updateInstallInfo];
}

- (void)updateInstallInfo
{
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *installTitle = [NSString stringWithFormat:NSLocalizedString(@"install_title", nil), version];
	
	[_window setTitle:installTitle];
	[_installTitle setStringValue:installTitle];
	[_installText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"install_msg", nil), version]];
	[_installButton setTitle:NSLocalizedString(@"install", nil)];
	[_removeButton setEnabled:NO];
    
    if ([self _isInstalled]) {
        NSBundle *bundle = [NSBundle bundleWithPath:[SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename]];
        
        if (bundle) {
            NSString *message, *buttonText;
            
            if (![[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]) {
                buttonText = NSLocalizedString(@"update", nil);
                message = [NSString stringWithFormat:NSLocalizedString(@"installed_update_msg", nil), version];
            } else {
                buttonText = NSLocalizedString(@"reinstall", nil);
                message = [NSString stringWithFormat:NSLocalizedString(@"installed_reinstall_msg", nil), version];
            }
            
            [_installButton setTitle:buttonText];
            [_installText setStringValue:message];
            
            [_removeButton setEnabled:YES];
        }
    } else {
        [_removeButton setEnabled:NO];
    }
}

- (void)displaySheetTitled:(NSString *)title message:(NSString *)message defaultButton:(NSString *)defaultButton secondaryButton:(NSString *)secondaryButton callback:(SEL)callback
{
    NSBeginAlertSheet(NSLocalizedString(title, nil), NSLocalizedString(defaultButton, nil), NSLocalizedString(secondaryButton, nil), nil, _window, self, callback, NULL, nil, NSLocalizedString(message, nil), nil);
}

- (void)displayError:(NSError *)error
{
    [self displaySheetTitled:@"error_title" message:[error localizedDescription] defaultButton:nil secondaryButton:nil callback:NULL];
}

- (void)setLaunchAtLogin:(BOOL)enabled
{
    //Remove from login items
    SystemEventsApplication *app = [SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"];
    
    for (id nextItem in [app loginItems]) {
        if ([[nextItem name] isEqualToString:@"ChaxHelperApp"]) {
            [[app loginItems] removeObject:nextItem];
            break;
        }
    }
    
    //Readd to login items
    if (enabled) {
        NSString *path = [self installedHelperAppPath];
        NSString *source = [NSString stringWithFormat:@"tell application \"System Events\" to make new login item with properties {path:\"%@\", hidden:false} at end", path];
        NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
        
        [script executeAndReturnError:nil];
	}
}

#pragma mark -
#pragma mark Paths

- (NSString *)chaxAdditionPath
{
    return [[NSBundle bundleForClass:[self class]] pathForResource:@"ChaxAddition" ofType:@"osax"];
}

- (NSString *)installedHelperAppPath
{
    NSBundle *installedAdditionsBundle = [NSBundle bundleWithPath:[SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename]];
    
    //pathForAuxiliaryExecutable nor pathForResource:ofType: seem to work here
    return [[[[installedAdditionsBundle bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"ChaxHelperApp.app"];
}

#pragma mark -
#pragma mark NSApplication Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	SInt32 version;
	
	if ((Gestalt(gestaltSystemVersion, &version) == noErr) && ((version < 0x1060) || (version > 0x1070))) {
        [self displaySheetTitled:@"version_title" message:@"version_msg" defaultButton:@"quit" secondaryButton:nil callback:@selector(versionSheetDidEnd:returnCode:contextInfo:)];
	}
}

#pragma mark -
#pragma mark IBActions

- (IBAction)install:(id)sender
{
    BOOL installed = NO;
    BOOL isDir = NO;
    NSError *error = nil;
    
    //Create ~/Library/ScriptingAdditions if it doesn't exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:SCRIPTING_ADDITIONS_PATH isDirectory:&isDir]) {
        installed = [self _createScriptingAdditionsDirectory];
    } else if (!isDir) {
        //~/Library/ScriptingAdditions exists, but it isn't a folder, eh?
        if (![[NSFileManager defaultManager] moveItemAtPath:SCRIPTING_ADDITIONS_PATH toPath:SCRIPTING_ADDITIONS_OLD_PATH error:&error]) {
            installed = [self _createScriptingAdditionsDirectory];
        }
    }
    
    //Remove the old version already installed
    if ([self _isInstalled]) {
        NSString *removePath = [SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename];
        
        [[NSFileManager defaultManager] removeItemAtPath:removePath error:&error];
        
        [self _quitChaxHelperApp];
    }
    
    //Copy ChaxAddition to ~/Library/ScriptingAdditions
    installed = [[NSFileManager defaultManager] copyItemAtPath:[self chaxAdditionPath] toPath:[SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename] error:&error];
    
    //Lastly, set the helper app to launch at login
    if (installed) {
        NSString *launchPath = [self installedHelperAppPath];
        NSURL *launchURL = [NSURL fileURLWithPath:launchPath];
        OSStatus err;
        
        //Remove quarantine from the daemon if necessary
        err = removexattr([launchPath fileSystemRepresentation], "com.apple.quarantine", 0);
        if (err != 0 && errno != ENOATTR) {
            NSLog(@"removexattr() failed! %d %d", err, errno);
        }
        
        [self setLaunchAtLogin:YES];
        
        LSApplicationParameters params;
        FSRef fsRef;
        
        CFURLGetFSRef((CFURLRef)launchURL, &fsRef);
        
        params.version = 0;
        params.flags = kLSLaunchDontSwitch | kLSLaunchNewInstance | kLSLaunchNoParams;
        params.application = &fsRef;
        params.environment = NULL;
        params.argv = NULL;
        params.initialEvent = NULL;
        
        LSOpenApplication(&params, NULL);
        
        [self displaySheetTitled:@"success_title" message:@"success_msg" defaultButton:@"donate" secondaryButton:@"quit" callback:@selector(installedSheetDidEnd:returnCode:contextInfo:)];
    } else {
        [self displayError:error];
    }
    
    [self updateInstallInfo];
}

- (IBAction)remove:(id)sender
{
    BOOL removed = NO;
    NSString *removePath = [SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename];
    NSError *error = nil;
    
    if ([self _isInstalled]) {
        removed = [[NSFileManager defaultManager] removeItemAtPath:removePath error:&error];
    }
    
    if (removed) {
        [self setLaunchAtLogin:NO];
        [self _quitChaxHelperApp];
        
        [self displaySheetTitled:@"remove_title" message:@"remove_msg" defaultButton:nil secondaryButton:nil callback:NULL];
    } else {
        [self displayError:error];
    }
    
    [self updateInstallInfo];
}

#pragma mark -
#pragma mark Sheet Callbacks

- (void)installedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[[NSWorkspace sharedWorkspace] openURL:DONATE_URL];
	} else if (returnCode == NSAlertAlternateReturn) {
		[NSApp terminate:nil];
	}
}

- (void)versionSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp terminate:nil];
}

#pragma mark -
#pragma mark Private

- (BOOL)_createScriptingAdditionsDirectory
{
    BOOL success = YES;
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:SCRIPTING_ADDITIONS_PATH withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self displayError:error];
        
        success = NO;
    }
    
    return success;
}

- (BOOL)_isInstalled
{
    NSString *removePath = [SCRIPTING_ADDITIONS_PATH stringByAppendingPathComponent:ChaxAdditionFilename];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:removePath];
}

- (void)_quitChaxHelperApp
{
    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:@"tell application \"ChaxHelperApp\" to quit"] autorelease];
    [script executeAndReturnError:nil];
}

@end
