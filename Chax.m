/*
 * Chax.m
 *
 * Copyright (c) 2007- Kent Sutherland
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

#import <Sparkle/Sparkle.h>
#import "Chax.h"
#import "iChat5.h"
#import "UnifiedPeopleListController_Provider.h"
#import "StatusChangeController.h"
#import "LogViewerController.h"
#import "DonateWindowController.h"
#import "ActivityWindowController.h"

NSString *ChaxBundleIdentifier = @"com.ksuther.chax";
NSString *ChaxLibBundleIdentifier = @"com.ksuther.chax.lib";
NSString *ChaxAdditionBundleIdentifier = @"com.ksuther.chax.addition";

static NSInteger kChaxDonateRequestFirstInterval = 604800;
static NSInteger kChaxDonateRequestSecondInterval = 2678400;

static NSArray *_chaxMenuItems = nil;
static NSMutableDictionary *_imageDictionary = nil;
//static NSString *_previousMessage = nil;
//static BOOL _screensaverAwayed = NO;

static NSString *_bundlePath = nil;
static id _updater = nil;

@implementation Chax

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bundleDidLoadNotificationReceived:) name:NSBundleDidLoadNotification object:nil];
	
	//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(screensaverNotificationReceived:) name:@"com.apple.screensaver.didstart" object:nil];
	//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(screensaverNotificationReceived:) name:@"com.apple.screensaver.didstop" object:nil];
	
	[pool release];
}

#pragma mark -

+ (void)bundleDidLoadNotificationReceived:(NSNotification *)note
{
    if ([[[note object] bundleIdentifier] isEqualToString:ChaxLibBundleIdentifier]) {
        _imageDictionary = [[NSMutableDictionary alloc] init];
        
        NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:ChaxAdditionBundleIdentifier] pathForImageResource:@"Chax"]] autorelease];
        [image setName:@"ChaxIcon"];
        [_imageDictionary setObject:image forKey:@"ChaxIcon"];
        
        NSImage *badgeImage = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForImageResource:@"menu-badge"]] autorelease];
        [badgeImage setName:@"ChaxBadge"];
        [_imageDictionary setObject:badgeImage forKey:@"ChaxBadge"];
        
        [self addMenuItems];
        [self registerURLHandlers];
        [self setupSparkle];
        [self performSelector:@selector(displayDonateWindowIfWanted) withObject:nil afterDelay:2.0];
        [NSClassFromString(@"Prefs") setKnockKnock:![Chax boolForKey:@"SkipNewMessageNotification"]];
        
        [StatusChangeController sharedController]; //Load the Growl framework and register for status changes
        
        if ([Chax boolForKey:@"ConfirmQuit"]) {
            [[NSProcessInfo processInfo] disableSuddenTermination];
        }
        
        //Display the unified contact list if it has never been shown before
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Chax.Visible"] == nil || [[NSClassFromString(@"UnifiedPeopleListController") sharedController] prefVisible]) {
            //Calling showWindow: instead of displayIfPrefVisible ensures that the window is made key if no other windows are opened
            [[NSClassFromString(@"UnifiedPeopleListController") sharedController] performSelector:@selector(showWindow:) withObject:nil afterDelay:0.0];
        }
        
        PerformAutomaticSwizzle();
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadContactList" object:nil];
    }
}

+ (void)registerURLHandlers
{
    LSSetDefaultHandlerForURLScheme((CFStringRef)@"ichat", CFSTR("com.apple.iChat"));
}

+ (void)setupSparkle
{
    NSBundle *chaxBundle = [NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier];
    
    //Load Sparkle framework
    if (!NSClassFromString(@"SUUpdater")) {
        NSString *frameworkPath = [[chaxBundle privateFrameworksPath] stringByAppendingPathComponent:@"Sparkle.framework"];
        NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
        
        if (![framework load]) {
            NSLog(@"Chax: There was an error loading Sparkle.framework from %@", frameworkPath);
        }
    }
    
    _bundlePath = [chaxBundle bundlePath]; //Save the original bundle path since the original one will move when updating
    
    _updater = [[NSClassFromString(@"SUUpdater") updaterForBundle:[NSBundle bundleWithIdentifier:ChaxAdditionBundleIdentifier]] retain];
    [_updater setDelegate:self];
}

+ (void)checkForUpdates
{
    [_updater checkForUpdates:nil];
}

+ (void)displayDonateWindowIfWanted
{
    //Check if the donation window should be shown
    NSString *msg = nil;
    NSInteger time = [Chax integerForKey:@"NextDonateRequest"];
    NSInteger count = [Chax integerForKey:@"DonateCount"];
    
    if (count == 0) {
        [Chax setInteger:[NSDate timeIntervalSinceReferenceDate] + kChaxDonateRequestFirstInterval forKey:@"NextDonateRequest"];
        [Chax setInteger:1 forKey:@"DonateCount"];
    } else if (count == 1 && [NSDate timeIntervalSinceReferenceDate] > time) {
        msg = @"Thank you for using Chax. Please consider making a donation to support the development of Chax if you find it to be a useful addition to iChat. This message will only appear once more.";
        [Chax setInteger:2 forKey:@"DonateCount"];
        [Chax setInteger:[NSDate timeIntervalSinceReferenceDate] + kChaxDonateRequestSecondInterval forKey:@"NextDonateRequest"];
    } else if (count == 2 && [NSDate timeIntervalSinceReferenceDate] > time) {
        msg = @"Thank you for continuing to use Chax. Please consider making a donation to support the development of Chax if you find it to be a useful addition to iChat. This message will not appear again.";
        [Chax setInteger:-1 forKey:@"DonateCount"];
        [Chax setInteger:0 forKey:@"NextDonateRequest"];
    }
    
    if (msg) {
        DonateWindowController *controller = [[DonateWindowController alloc] initWithMessage:ChaxLocalizedString(msg)];
        [controller showWindow:nil];
    }
}

+ (void)addMenuItems
{
	NSMutableArray *menuItems = [NSMutableArray array];
	NSMenuItem *menuItem;
	NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:3] submenu];
	NSMenu *buddiesMenu = [[[NSApp mainMenu] itemAtIndex:4] submenu];
	//NSMenu *audioMenu = [[[NSApp mainMenu] itemAtIndex:5] submenu];
    
	//Toggle text status menu item
	menuItem = [viewMenu insertItemWithTitle:ChaxLocalizedString(@"Show Text Status") action:@selector(chax_toggleTextStatus:) keyEquivalent:@"" atIndex:5];
	[menuItem setTag:ChaxMenuItemShowTextStatus];
	[menuItems addObject:menuItem];
	
	//Send camera snapshot menu item
	menuItem = [buddiesMenu insertItemWithTitle:ChaxLocalizedString(@"Send Camera Snapshot...") action:@selector(chax_sendCameraSnapshot:) keyEquivalent:@"j" atIndex:14];
	[menuItem setTag:ChaxMenuItemCameraSnapshot];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[menuItems addObject:menuItem];
	
	//Always on top menu item
	menuItem = [[NSApp windowsMenu] insertItemWithTitle:ChaxLocalizedString(@"Always on Top") action:@selector(chax_toggleAlwaysOnTop:) keyEquivalent:@"" atIndex:3];
	[menuItem setTag:ChaxMenuItemAlwaysOnTop];
	[menuItems addObject:menuItem];
	
	//Log viewer menu item
	menuItem = [[NSApp windowsMenu] addItemWithTitle:ChaxLocalizedString(@"Log Viewer") action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTag:ChaxMenuItemLogViewer];
	[menuItem setTarget:[LogViewerController sharedController]];
	[menuItems addObject:menuItem];
	
	//Activity window menu item
	menuItem = [[NSApp windowsMenu] addItemWithTitle:ChaxLocalizedString(@"Activity") action:@selector(showWindow:) keyEquivalent:@"a"];
	[menuItem setTag:ChaxMenuItemActivityViewer];
	[menuItem setTarget:[ActivityWindowController sharedController]];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[menuItems addObject:menuItem];
	
	//All contacts menu item
	menuItem = [[NSApp windowsMenu] addItemWithTitle:ChaxLocalizedString(@"All Contacts") action:@selector(showPeopleListController:) keyEquivalent:@"1"];
	[menuItem setTag:ChaxMenuItemAllContacts];
	[menuItem setTarget:[NSClassFromString(@"Fezz") sharedInstance]];
	[menuItem setRepresentedObject:[[NSClassFromString(@"UnifiedPeopleListController") sharedController] representedAccount]];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[menuItems addObject:menuItem];
	
	//Mute alert sounds menu item
	/*menuItem = [audioMenu addItemWithTitle:ChaxLocalizedString(@"mute_alert_sounds") action:@selector(chax_toggleMuteAlerts:) keyEquivalent:@""];
	[menuItem setTag:MUTE_ALERTS_MENU_ITEM];
	[menuItem setTarget:self];
	[menuItems addObject:menuItem];
	
	//By handle menu item
	menuItem = [[[viewMenu itemAtIndex:13] submenu] insertItemWithTitle:ChaxLocalizedString(@"by_handle") action:@selector(chax_sortByHandle:) keyEquivalent:@"" atIndex:3];
	[menuItem setTag:BY_HANDLE_MENU_ITEM];
	[menuItems addObject:menuItem];*/
	
    if (![Chax boolForKey:@"HideMenuBadge"]) {
        [menuItems makeObjectsPerformSelector:@selector(setImage:) withObject:[NSImage imageNamed:@"ChaxBadge"]];
    }
	
	_chaxMenuItems = [[NSArray alloc] initWithArray:menuItems];
}

+ (NSArray *)menuItems
{
	return _chaxMenuItems;
}

#pragma mark -
#pragma mark Sparkle Delegate

+ (void)updaterWillRelaunchApplication:(id)updater
{
    //Quit ChaxHelperApp
    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:@"tell application \"ChaxHelperApp\" to quit"] autorelease];
    
    [script executeAndReturnError:nil];
    
    //Relaunch ChaxHelperApp
    NSString *launchPath = [[NSBundle bundleWithIdentifier:ChaxAdditionBundleIdentifier] pathForResource:@"ChaxHelperApp" ofType:@"app"];
    
    if (launchPath) {
        OSStatus err;
        LSApplicationParameters params;
        FSRef fsRef;
        
        CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:launchPath], &fsRef);
        
        params.version = 0;
        params.flags = kLSLaunchDontSwitch | kLSLaunchNewInstance | kLSLaunchNoParams;
        params.application = &fsRef;
        params.environment = NULL;
        params.argv = NULL;
        params.initialEvent = NULL;
        
        err = LSOpenApplication(&params, NULL);
        if (err != noErr) {
            NSLog(@"Failed to relaunch ChaxHelperApp: LSOpenApplication() failed (%d)", err);
        }
    }
}

+ (NSString *)pathToRelaunchForUpdater:(id)updater
{
    return [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iChat.app"];
}

#pragma mark -
#pragma mark Chax Defaults

+ (BOOL)boolForKey:(NSString *)key
{
	return CFPreferencesGetAppBooleanValue((CFStringRef)key, (CFStringRef)ChaxBundleIdentifier, nil);
}

+ (int)integerForKey:(NSString *)key
{
	return CFPreferencesGetAppIntegerValue((CFStringRef)key, (CFStringRef)ChaxBundleIdentifier, nil);
}

+ (NSData *)dataForKey:(NSString *)key
{
	id object = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)ChaxBundleIdentifier);
	if (object && CFGetTypeID(object) == CFDataGetTypeID()) {
		return [object autorelease];
	} else {
		[object release];
		return nil;
	}
}

+ (NSString *)stringForKey:(NSString *)key
{
	id object = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)ChaxBundleIdentifier);
	if (object && CFGetTypeID(object) == CFStringGetTypeID()) {
		return [object autorelease];
	} else {
		[object release];
		return nil;
	}
}

+ (id)objectForKey:(NSString *)key
{
	return [(id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)ChaxBundleIdentifier) autorelease];
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key
{
	NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dictionary = [[[df persistentDomainForName:ChaxBundleIdentifier] mutableCopy] autorelease];
	
	if (!dictionary) {
		dictionary = [NSMutableDictionary dictionary];
	}
	
	[dictionary setObject:[NSNumber numberWithBool:value] forKey:key];
	[df setPersistentDomain:dictionary forName:ChaxBundleIdentifier];
}

+ (void)setInteger:(int)value forKey:(NSString *)key
{
	NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dictionary = [[[df persistentDomainForName:ChaxBundleIdentifier] mutableCopy] autorelease];
	
	if (!dictionary) {
		dictionary = [NSMutableDictionary dictionary];
	}
	
	[dictionary setObject:[NSNumber numberWithInt:value] forKey:key];
	[df setPersistentDomain:dictionary forName:ChaxBundleIdentifier];
}

+ (void)setObject:(id)value forKey:(NSString *)key
{
	NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *dictionary = [[[df persistentDomainForName:ChaxBundleIdentifier] mutableCopy] autorelease];
	
	if (!dictionary) {
		dictionary = [NSMutableDictionary dictionary];
	}
	
	[dictionary setObject:value forKey:key];
	[df setPersistentDomain:dictionary forName:ChaxBundleIdentifier];
}

@end
