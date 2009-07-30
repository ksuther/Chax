/*
 * UnifiedPeopleListController_Provider.m
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

#import "UnifiedPeopleListController_Provider.h"
#import "UnifiedAccount.h"
#import "Chax.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UnifiedPeopleListController_Provider

+ (void)load
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [BundleUtilities subclass:NSClassFromString(@"PeopleListController") usingClassName:@"UnifiedPeopleListController" providerClass:self];
    
    [pool release];
}

+ (id)sharedController
{
	static id sharedController = nil;
	
	if (!sharedController) {
		IMAccount *account = [[[UnifiedAccount alloc] initWithUniqueID:@"Chax" service:nil] autorelease];
		
		[account setAccountLoginStatus:4];
		[account setString:ChaxLocalizedString(@"All Accounts") forKey:@"LoginAs"];
		
		sharedController = [[NSClassFromString(@"UnifiedPeopleListController") alloc] initWithAccount:account];
	}
	
	return sharedController;
}

- (id)initWithAccount:(IMAccount *)account
{
	struct objc_super superData = {self, [self superclass]};
	
	if ( (self = objc_msgSendSuper(&superData, @selector(initWithAccount:), account)) ) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chax_notificationReceived:) name:@"ReloadContactList" object:nil];
		
		[self setPrefIdentifier:@"Chax"];
		[self setName:ChaxLocalizedString(@"Contacts")];
	}
	return self;
}

- (void)dealloc
{
	//[_addMenu release];
	//[_addGroupString release];
	
    struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(dealloc));
}

/*- (NSWindow *)window
{
    struct objc_super superData = {self, [self superclass]};
	
	id superresult = objc_msgSendSuper(&superData, @selector(window));
    
    NSLog(@"%@", superresult);
    
    return superresult;
}*/

- (void)loadWindow
{
	struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(loadWindow));
	
	[[self window] setFrame:NSRectFromString([[NSUserDefaults standardUserDefaults] objectForKey:@"Chax.WindowSize"]) display:NO];
}

- (void)windowDidLoad
{
	struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(windowDidLoad));
	
	/*NSMenu *addButtonMenu = [[self valueForKey:@"_addButton"] menu];
	
	_addGroupString = [[[addButtonMenu itemAtIndex:1] title] copy];
	
	if (!_addGroupString) {
		_addGroupString = [[NSString alloc] initWithString:@"Add Group..."];
	}*/
}

- (void)windowDidMove:(id)fp8
{
	NSRect frame = [[self window] frame];
	frame.origin.y += frame.size.height;
	
	if (![self isTableCollapsed]) {
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(frame) forKey:@"Chax.WindowSize"];
	}
	
    struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(windowDidMove:), fp8);
}

- (void)windowDidResize:(id)fp8
{
	NSRect frame = [[self window] frame];
	frame.origin.y += frame.size.height;
	
	if (![self isTableCollapsed]) {
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(frame) forKey:@"Chax.WindowSize"];
	}
	
	struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(windowDidResize:), fp8);
}

- (BOOL)supportsOfflineToggle
{
	return YES;
}

- (BOOL)supportsGroups
{
	return YES;
}

- (BOOL)peopleList:(id)fp8 canRemoveRows:(id)fp12
{
	return YES;
}

- (void)setGroupsSortOrder:(id)fp8
{
    struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(setGroupsSortOrder:), fp8);
	
	[self refreshList];
}

- (void)logServiceInOrOut:(id)sender
{
	if ([(NSArray *)[[IMAccountController sharedInstance] allConnectedAccounts] count] == 0) {
		NSArray *accounts = [[IMAccountController sharedInstance] allActiveAccounts];
		
		for (Account *account in accounts) {
			if ([account autoLogin]) {
				[(IMAccountController *)[IMAccountController sharedInstance] autoLogin];
				[[self representedAccount] setAccountLoginStatus:4];
				return;
			}
		}
		
		[[self representedAccount] setAccountLoginStatus:0];
	} else {
		[[IMDaemonController sharedController] logoutAllAccounts];
		[[self representedAccount] setAccountLoginStatus:0];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(logServiceInOrOut:)) {
		if ([(NSArray *)[[IMAccountController sharedInstance] allConnectedAccounts] count] == 0) {
			[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Log In to %@", @"Log In to %@"), [[self representedAccount] login]]];
		} else {
			[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Log Out of %@", @"Log Out of %@"), [[self representedAccount] login]]];
		}
		return YES;
	}
	
    struct objc_super superData = {self, [self superclass]};
	
	return (BOOL)objc_msgSendSuper(&superData, @selector(validateMenuItem:), menuItem);
}

- (void)processIMHandleGroupChange:(IMHandle *)imHandle
{
	[self reloadContacts];
}

/*- (void)_arrangesByGroupChanged
{
	struct objc_super superData = {self, [self superclass]};
	
	objc_msgSendSuper(&superData, @selector(_arrangesByGroupChanged));
	
	if (!_addMenu) {
		//Build the menu delayed the first time
		[self performSelector:@selector(rebuildAddBuddyMenu) withObject:nil afterDelay:2.0];
	} else {
		[self rebuildAddBuddyMenu];
	}
}*/

- (void)reloadContacts
{
	[[self sourcePeople] beginCoalescedChanges];
	
	[[self peopleList] removeAllIMHandlesAndGroups:YES];
	
	for (PeopleListController *pl in [NSClassFromString(@"PeopleListController") peopleListControllers]) {
		if (![self isEqual:pl]) {
			NSArray *handles = [[pl peopleList] allIMHandles];
			
			for (IMHandle *nextIMHandle in handles) {
				[[self sourcePeople] addIMHandle:nextIMHandle];
			}
		}
	}
	
	[[self sourcePeople] endCoalescedChanges];
}

- (void)rebuildAddBuddyMenu
{
	/*if (!_addMenu) {
		_addMenu = [[NSMenu alloc] init];
	}
	
	NSMenu *addButtonMenu = [[self valueForKey:@"_addButton"] menu];
	
	if (!_addGroupString) {
		_addGroupString = [[[addButtonMenu itemAtIndex:1] title] copy];
		
		if (!_addGroupString) {
			_addGroupString = [[NSString alloc] initWithString:@"Add Group..."];
		}
	}
	
	while (_addMenu.numberOfItems > 0) {
		[_addMenu removeItemAtIndex:0];
	}
	
	NSArray *connectedAccounts = [[IMAccountController sharedInstance] allConnectedAccounts];
	
	for (IMAccount *nextAccount in connectedAccounts) {
		NSString *description = [nextAccount description];
		
		if (description) {
			NSMenu *accountSubmenu = [[[NSMenu alloc] init] autorelease];
			
			[[_addMenu addItemWithTitle:description action:nil keyEquivalent:@""] setSubmenu:accountSubmenu];
			
			[[accountSubmenu addItemWithTitle:NSLocalizedString(@"Add Buddy\\U2026", nil) action:@selector(addABuddyChax:) keyEquivalent:@""] setRepresentedObject:[nextAccount uniqueID]];
			[[accountSubmenu addItemWithTitle:_addGroupString action:@selector(addAGroupChax:) keyEquivalent:@""] setRepresentedObject:[nextAccount uniqueID]];
		}
	}
	
	[[self valueForKey:@"_addButton"] setUsesMenu:YES];
	[[self valueForKey:@"_addButton"] setMenu:_addMenu];*/
}

- (void)addABuddyChax:(id)sender
{
	IMAccount *account = [[IMAccountController sharedInstance] accountForUniqueID:[sender representedObject]];
	PeopleListController *accountPeopleListController = [NSClassFromString(@"PeopleListController") peopleListControllerWithRepresentedAccount:account];
	
	AddBuddy *addBuddy = [accountPeopleListController addBuddy];
	
	id groups = [accountPeopleListController groupsWithCapability:nil];
	
	[addBuddy openForNewIMHandleWithGroups:groups buddyWindow:[self window]];
}

- (void)addAGroupChax:(id)sender
{
	IMAccount *account = [[IMAccountController sharedInstance] accountForUniqueID:[sender representedObject]];
	PeopleListController *accountPeopleListController = [NSClassFromString(@"PeopleListController") peopleListControllerWithRepresentedAccount:account];
	
	[accountPeopleListController showWindow:nil];
	[NSClassFromString(@"GroupsEditorController") addGroupForPeopleListController:accountPeopleListController];
}

@end
