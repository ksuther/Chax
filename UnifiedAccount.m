/*
 * UnifiedAccount.m
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

#import "UnifiedAccount.h"
#import "UnifiedPeopleListController_Provider.h"

@implementation UnifiedAccount

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
    return [NSApp myStatusMessage];
}

- (void)setInvisible:(BOOL)flag
{
	[[[NSClassFromString(@"Fezz") sharedInstance] valueForKey:@"statusController"] setInvisible:flag];
	[super setInvisible:flag];
}

- (void)loginAccount
{
	[self setAccountLoginStatus:4];
	[NSClassFromString(@"Fezz") connectAndAutoLogin];
	[super loginAccount];
}

- (void)setAccountLoginStatus:(int)fp8
{
	if (fp8 == 2) {
		[[IMDaemonController sharedController] logoutAllAccounts];
		[super setAccountLoginStatus:0];
	} else {
		[super setAccountLoginStatus:fp8];
	}
}

- (void)reorderGroups:(id)fp8
{
	[Chax setObject:fp8 forKey:@"UnifiedGroupOrder"];
	
	[_groups release];
	_groups = [fp8 copy];
	
	[super reorderGroups:fp8];
}

- (NSArray *)groupList
{
	NSMutableArray *sortedGroups = [[[Chax objectForKey:@"UnifiedGroupOrder"] mutableCopy] autorelease];
	NSMutableArray *unusedGroups = [[[Chax objectForKey:@"UnifiedGroupOrder"] mutableCopy] autorelease];
	NSArray *handles = [_buddyList people];
	
	for (IMHandle *nextHandle in handles) {
		NSString *group = [[nextHandle groups] anyObject];
		
		if ([unusedGroups containsObject:group]) {
			[unusedGroups removeObject:group];
		}
	}
	
	[sortedGroups removeObjectsInArray:unusedGroups];
	
	return sortedGroups;
}

- (void)didWakeNotification:(id)fp8
{
	//Do nothing
}

- (void)willSleepNotification:(id)fp8
{
	//Prevents a crash when using groups
	[[[NSClassFromString(@"PeopleListController") peopleListControllerWithRepresentedAccount:self] peopleList] removeAllIMHandlesAndGroups:YES];
}

@end
