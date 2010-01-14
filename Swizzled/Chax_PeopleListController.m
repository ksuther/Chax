/*
 * Chax_PeopleListController.m
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

#import <Carbon/Carbon.h>
#import "Chax_PeopleListController.h"
#import "Chax_PeopleList.h"
//#import "UnifiedPeopleListController_Provider.h"

@implementation Chax_PeopleListController

+ (void)load
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *controllers = [NSClassFromString(@"PeopleListController") peopleListControllers];
	
	for (PeopleListController *plc in controllers) {
        [[NSNotificationCenter defaultCenter] addObserver:plc selector:@selector(chax_notificationReceived:) name:@"ReloadContactList" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:plc selector:@selector(chax_notificationReceived:) name:@"ResizeContactList" object:[plc peopleList]];
    }
    
    [pool release];
}

#pragma mark -
#pragma mark Added Methods

- (void)chax_toggleTextStatus:(NSMenuItem *)sender
{
	[sender setState:(([sender state] == NSOnState) ? NSOffState : NSOnState)];
	[Chax setBool:(([sender state] == NSOnState) ? NO : YES) forKey:[NSString stringWithFormat:@"%@.HideTextStatus", [self prefIdentifier]]];
	[(NSTableView *)[[self peopleList] table] reloadData];
}

- (void)chax_notificationReceived:(NSNotification *)note
{
	if ([[note name] isEqualToString:@"ReloadContactList"]) {
		[(NSTableView *)[[self peopleList] table] reloadData];
		[[self peopleList] performSelector:@selector(chax_updateRowHeights) withObject:nil afterDelay:0.0];
	}
	
	[self performSelector:@selector(chax_resizeWindow) withObject:nil afterDelay:0.0];
}

- (void)chax_resizeWindow
{
    StatusController *statusController = [self valueForKey:@"_myStatusController"];
    
	if ([statusController currentStatus] > 1 && [Chax boolForKey:@"AutoresizeContactList"] && [statusController currentStatus] > 1) {
		NSRect frame = [[self window] frame], screenFrame = [[[self window] screen] frame];
		NSRect preferredFrame = [self windowWillUseStandardFrame:[self window] defaultFrame:screenFrame];
		
		//if the bottom edge of the window is within 20 pixels of the bottom and the top of the buddy list isn't at the top of the screen, resize upwards if possible
		//otherwise resize down as usual
		if (frame.origin.y < 20 && (screenFrame.size.height - GetMBarHeight() - (frame.origin.y + frame.size.height) > 10)) {
			//we're within 30 pixels of the bottom of the screen, this means we should resize upward
			preferredFrame.origin.y = frame.origin.y;
		} else {
			preferredFrame.origin.y -= 1;
		}
		
		preferredFrame.size.width = [[self window] frame].size.width;
		preferredFrame.origin.x = [[self window] frame].origin.x;
        preferredFrame.size.height += 1;
		
		[[self window] setFrame:preferredFrame display:YES animate:YES];
	}
}

#pragma mark -
#pragma mark Swizzled Methods

- (void)chax_swizzle_dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[self chax_swizzle_dealloc];
}

- (void)chax_swizzle_windowDidLoad
{
	[self chax_swizzle_windowDidLoad];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chax_notificationReceived:) name:@"ReloadContactList" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chax_notificationReceived:) name:@"ResizeContactList" object:[self peopleList]];
	
	/*if ([Chax boolForKey:@"HideContactListsWhenInactive"]) {
		[[self window] setHidesOnDeactivate:YES];
	}*/
}

- (void)chax_swizzle_displayWithKey:(BOOL)fp8
{
    //Ensures that only the unified contact list appears at launch
    if (![Chax boolForKey:@"PreferAllContacts"] || [[NSClassFromString(@"Fezz") sharedInstance] deferredLaunchComplete]) {
        [self chax_swizzle_displayWithKey:fp8];
    }
}

- (BOOL)chax_swizzle_validateMenuItem:(NSMenuItem *)sender
{
	if ([sender tag] == ChaxMenuItemShowTextStatus) {
		[sender setState:([Chax boolForKey:[NSString stringWithFormat:@"%@.HideTextStatus", [self prefIdentifier]]] ? NSOffState : NSOnState)];
	} else if ([sender tag] == ChaxMenuItemByHandle) {
		[sender setState:[[self peopleList] sortOrder] == 100 ? NSOnState : NSOffState];
	}
	
	return [self chax_swizzle_validateMenuItem:sender];
}

- (void)chax_swizzle_toggleHidePictures:(id)fp8
{
	[self chax_swizzle_toggleHidePictures:fp8];
	[[self peopleList] performSelector:@selector(chax_updateRowHeights) withObject:nil afterDelay:0];
	[self chax_resizeWindow];
}

@end
