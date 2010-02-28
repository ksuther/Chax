/*
 * UnifiedAccount.m
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

#import "UnifiedAccount_Provider.h"
#import "UnifiedPeopleListController_Provider.h"
#import <objc/runtime.h>
#import <objc/message.h>

//Used to keep the unified account from logging out all other accounts
//We want these other accounts to log themselves out because of a sleep preparation notice
//so that they attempt to log themselves back in as usual when waking back up
//This should fix the problem where some accounts aren't coming back as expected when waking up
static BOOL _preparingToSleep = NO;

@implementation UnifiedAccount_Provider

+ (void)load
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [BundleUtilities subclass:NSClassFromString(@"Account") usingClassName:@"UnifiedAccount" providerClass:self];
    
    [pool release];
}

- (BOOL)justLoggedIn
{
	return NO;
}

- (unsigned long long)capabilities
{
	return 1648963082045;
}

- (IMPersonStatus)myStatus
{
    return [IMService myStatus];
}

- (NSString *)myStatusMessage
{
    NSArray *connectedAccounts = [[NSClassFromString(@"IMAccountController") sharedInstance] allConnectedAccounts];
    NSString *status = [NSApp myStatusMessage];
    
    if ([connectedAccounts count] > 0) {
        IMAccount *anAccount = [connectedAccounts lastObject];
        NSString *playingString = [anAccount myNowPlayingString];
        
        if (playingString != nil) {
            status = playingString;
        }
    }
    
    return status;
}

- (NSString *)menuItemDescription
{
    return ChaxLocalizedString(@"all accounts");
}

- (BOOL)isActive
{
    return YES;
}

- (void)setInvisible:(BOOL)flag
{
	[[[NSClassFromString(@"Fezz") sharedInstance] valueForKey:@"statusController"] setInvisible:flag];
    
    struct objc_super superData = {self, [self superclass]};
	objc_msgSendSuper(&superData, @selector(setInvisible:), flag);
}

- (void)loginAccount
{
	[self setAccountLoginStatus:4];
	[NSClassFromString(@"Fezz") connectAndAutoLogin];
    
    struct objc_super superData = {self, [self superclass]};
	objc_msgSendSuper(&superData, @selector(loginAccount));
}

- (void)setAccountLoginStatus:(int)fp8
{
	if (fp8 == 2 && !_preparingToSleep) {
		[[IMDaemonController sharedController] logoutAllAccounts];
        fp8 = 0;
	}
    
    struct objc_super superData = {self, [self superclass]};
	objc_msgSendSuper(&superData, @selector(setAccountLoginStatus:), fp8);
}

- (void)reorderGroups:(id)fp8
{
	[Chax setObject:fp8 forKey:@"UnifiedGroupOrder"];
    
	[[self valueForKey:@"_groups"] release];
    object_setInstanceVariable(self, "_groups", [fp8 copy]);
    
    struct objc_super superData = {self, [self superclass]};
	objc_msgSendSuper(&superData, @selector(reorderGroups:), fp8);
}

- (NSArray *)groupList
{
	NSMutableArray *sortedGroups = [[[Chax objectForKey:@"UnifiedGroupOrder"] mutableCopy] autorelease];
	NSMutableArray *unusedGroups = [[[Chax objectForKey:@"UnifiedGroupOrder"] mutableCopy] autorelease];
	NSArray *handles = [[self valueForKey:@"_buddyList"] people];
	
	for (IMHandle *nextHandle in handles) {
		NSString *group = [[nextHandle groups] anyObject];
		
		if ([unusedGroups containsObject:group]) {
			[unusedGroups removeObject:group];
		}
	}
	
	[sortedGroups removeObjectsInArray:unusedGroups];
	
	return sortedGroups;
}

- (void)renameGroup:(id)fp8 to:(id)fp12
{
    //Iterate over all accounts and rename any applicable group
    for (IMAccount *nextAccount in [[IMAccountController sharedInstance] allConnectedAccounts]) {
        if ([[nextAccount groupList] containsObject:fp8]) {
            [nextAccount renameGroup:fp8 to:fp12];
        }
    }
}

- (void)changeBuddyList:(id)fp8 add:(BOOL)fp12 groups:(id)fp16 atLocation:(int)fp20
{
    //Iterate over all accounts and delete any applicable groups
    for (IMAccount *nextAccount in [[IMAccountController sharedInstance] allConnectedAccounts]) {
        for (NSString *nextGroup in fp16) {
            if ([[nextAccount groupList] containsObject:nextGroup]) {
                [nextAccount changeBuddyList:fp8 add:fp12 groups:[NSSet setWithObject:nextGroup] atLocation:fp20];
            }
        }
    }
}

- (void)systemDidWake
{
    _preparingToSleep = NO;
    
    //Recconnect on wake code has been moved to -[Chax_Account chax_swizzle_nowLoggedIn]
}

- (void)systemWillSleep
{
    _preparingToSleep = YES;
    
    [self logoutAccount];
}

/*- (void)willSleepNotification:(id)fp8
{
	//Prevents a crash when using groups
	[[[NSClassFromString(@"PeopleListController") peopleListControllerWithRepresentedAccount:self] peopleList] removeAllIMHandlesAndGroups:YES];
}*/

@end
