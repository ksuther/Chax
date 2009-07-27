/*
 * Chax.m
 *
 * Copyright (c) 2007-2009 Kent Sutherland
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

#import "Chax.h"
#import "iChat5.h"
#import "UnifiedPeopleListController_Provider.h"

NSString *ChaxBundleIdentifier = @"com.ksuther.chax";

static NSInteger kChaxDonateRequestFirstInterval = 604800;
static NSInteger kChaxDonateRequestSecondInterval = 2678400;

static NSArray *_chaxMenuItems = nil;
static NSString *_previousMessage = nil;
static BOOL _screensaverAwayed = NO;

@implementation Chax

+ (void)load
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:NSApplicationWillFinishLaunchingNotification object:nil];
	
	//[StatusChangeController sharedController]; //Load the Growl framework and register for Presentity status changes
	
	//[Prefs setKnockKnock:![Chax boolForKey:@"SkipNewMessageNotification"]];
	
	//[[UpdateController sharedController] setAutomaticCheckingEnabled:[Chax boolForKey:@"AutoUpdateChax"]];
	
	//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(screensaverNotificationReceived:) name:@"com.apple.screensaver.didstart" object:nil];
	//[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(screensaverNotificationReceived:) name:@"com.apple.screensaver.didstop" object:nil];
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:NSApplicationDidFinishLaunchingNotification object:nil];
	
	//Display the unified contact list if it has never been shown before
	/*if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Chax.Visible"] == nil || [[UnifiedPeopleListController sharedController] prefVisible]) {
		//Calling showWindow: instead of displayIfPrefVisible ensures that the window is made key if no other windows are opened
		[[UnifiedPeopleListController sharedController] performSelector:@selector(showWindow:) withObject:nil afterDelay:0.0];
	}*/
	
	[pool release];
}

#pragma mark -

+ (void)notificationReceived:(NSNotification *)note
{
	[self registerDefaults];
	[self addMenuItems];
    
    //Display the unified contact list if it has never been shown before
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Chax.Visible"] == nil || [[NSClassFromString(@"UnifiedPeopleListController") sharedController] prefVisible]) {
		//Calling showWindow: instead of displayIfPrefVisible ensures that the window is made key if no other windows are opened
		[[NSClassFromString(@"UnifiedPeopleListController") sharedController] performSelector:@selector(showWindow:) withObject:nil afterDelay:0.0];
	}
}

+ (void)registerDefaults
{
	//Ask whether or not update checking should be enabled
	if ([Chax objectForKey:@"AutoUpdateChax"] == nil || [Chax objectForKey:@"AutoUpdateIncludeVersionInfo"] == nil) {
		//[[UpdateController sharedController] performSelector:@selector(promptForAutomaticUpdates) withObject:nil afterDelay:4.0];
	}
}

+ (void)addMenuItems
{
	NSImage *badgeImage = [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithIdentifier:ChaxBundleIdentifier] pathForImageResource:@"menu-badge"]] autorelease];
	NSMutableArray *menuItems = [NSMutableArray array];
	NSMenuItem *menuItem;
	NSMenu *viewMenu = [[[NSApp mainMenu] itemAtIndex:3] submenu];
	//NSMenu *buddiesMenu = [[[NSApp mainMenu] itemAtIndex:4] submenu];
	//NSMenu *audioMenu = [[[NSApp mainMenu] itemAtIndex:5] submenu];
	
	//Toggle text status menu item
	menuItem = [viewMenu insertItemWithTitle:ChaxLocalizedString(@"Show Text Status") action:@selector(chax_toggleTextStatus:) keyEquivalent:@"" atIndex:5];
	[menuItem setTag:ChaxMenuItemShowTextStatus];
	[menuItems addObject:menuItem];
	
	//Send camera snapshot menu item
	/*menuItem = [buddiesMenu insertItemWithTitle:ChaxLocalizedString(@"send_camera_snapshot") action:@selector(chax_sendCameraSnapshot:) keyEquivalent:@"j" atIndex:12];
	[menuItem setTag:SEND_CAMERA_SNAPSHOT_MENU_ITEM];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[menuItems addObject:menuItem];
	
	//Always on top menu item
	menuItem = [[NSApp windowsMenu] insertItemWithTitle:ChaxLocalizedString(@"always_on_top") action:@selector(chax_toggleAlwaysOnTop:) keyEquivalent:@"" atIndex:3];
	[menuItem setTag:ALWAYS_ON_TOP_MENU_ITEM];
	[menuItems addObject:menuItem];
	
	//Log viewer menu item
	menuItem = [[NSApp windowsMenu] addItemWithTitle:ChaxLocalizedString(@"log_viewer") action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTag:LOG_VIEWER_MENU_ITEM];
	[menuItem setTarget:[LogViewerController sharedController]];
	[menuItems addObject:menuItem];
	
	//Activity window menu item
	menuItem = [[NSApp windowsMenu] addItemWithTitle:ChaxLocalizedString(@"activity") action:@selector(showWindow:) keyEquivalent:@"a"];
	[menuItem setTag:ACTIVITY_WINDOW_MENU_ITEM];
	[menuItem setTarget:[ActivityWindowController sharedController]];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[menuItems addObject:menuItem];*/
	
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
	
	[menuItems makeObjectsPerformSelector:@selector(setImage:) withObject:badgeImage];
	
	_chaxMenuItems = [[NSArray alloc] initWithArray:menuItems];
}

+ (NSArray *)menuItems
{
	return _chaxMenuItems;
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
