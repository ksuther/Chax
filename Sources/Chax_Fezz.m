/*
 * Chax_Fezz.m
 *
 * Copyright (c) 2007-2011 Kent Sutherland
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

#import "Chax_Fezz.h"

@implementation Chax_Fezz

- (BOOL)chax_swizzle_applicationShouldHandleReopen:(id)fp8 hasVisibleWindows:(BOOL)fp12
{
    PeopleListController *uplc = [NSClassFromString(@"UnifiedPeopleListController") sharedController];
    
	if ([Chax boolForKey:@"PreferAllContacts"] && [NSApp keyWindow] == nil && (!fp12 || ![[uplc window] isVisible])) {
		[uplc showWindow:nil];
		return NO;
	}
	
	return [self chax_swizzle_applicationShouldHandleReopen:fp8 hasVisibleWindows:fp12];
}

- (NSApplicationTerminateReply)chax_swizzle_applicationShouldTerminate:(NSApplication *)sender
{
	NSApplicationTerminateReply reply;
	
	if ([Chax boolForKey:@"ConfirmQuit"] && [(NSArray *)[NSClassFromString(@"ChatWindowController") allChatWindowControllers] count] > 0) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"There are active chats. Are you sure you want to quit?", @"There are active chats. Are you sure you want to quit?")];
		[alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Yes")];
		[[alert addButtonWithTitle:NSLocalizedString(@"No", @"No")] setKeyEquivalent:@"\e"];
		
		reply = ([alert runModal] == NSAlertFirstButtonReturn) ? : NSTerminateCancel;
		[alert release];
	} else {
		reply = [self chax_swizzle_applicationShouldTerminate:sender];
	}
	
	return reply;
}

- (void)chax_swizzle__handleGURLAppleEvent:(id)fp8 reply:(id)fp12
{
	NSRange range = [[[fp8 descriptorAtIndex:1] stringValue] rangeOfString:@"iChat:openbuddylist?service="];
	
	if ([Chax boolForKey:@"PreferAllContacts"] && range.location != NSNotFound) {
		[[NSClassFromString(@"UnifiedPeopleListController") sharedController] showWindow:nil];
	} else {
		[self chax_swizzle__handleGURLAppleEvent:fp8 reply:fp12];
	}
}

@end
