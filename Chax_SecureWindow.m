/*
 * Chax_SecureWindow.m
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

#import "Chax_SecureWindow.h"

BOOL _chax_blockNextShowWindow = NO;

@implementation Chax_SecureWindow

+ (void)chax_blockNextShowWindow
{
	_chax_blockNextShowWindow = YES;
}

#pragma mark -

/*- (void)chax_swizzle_makeKeyAndOrderFront:(id)sender
{
	if (_chax_blockNextShowWindow) {
		_chax_blockNextShowWindow = NO;
		return;
	}
	
	[self chax_swizzle_makeKeyAndOrderFront:sender];
}*/

- (void)chax_toggleAlwaysOnTop:(id)sender
{
	[self setLevel:([self level] == NSNormalWindowLevel) ? NSStatusWindowLevel : NSNormalWindowLevel];
    [self setCollectionBehavior:NSWindowCollectionBehaviorParticipatesInCycle];
}

- (BOOL)validateMenuItem:(NSMenuItem *)sender
{
    BOOL valid;
    
	if ([sender tag] == ChaxMenuItemAlwaysOnTop && [self delegate] && ([[[self delegate] class] isEqual:NSClassFromString(@"ChatWindowController")] || [[[self delegate] class] isEqual:NSClassFromString(@"VideoChatController")] || [[[self delegate] class] isEqual:NSClassFromString(@"AudioChatController")])) {
		[sender setState:([self level] == NSNormalWindowLevel) ? NSOffState : NSOnState];
        
		valid = YES;
	} else {
        valid = [super validateMenuItem:sender];
    }
    
	return valid;
}

@end
