/*
 * DockIconController.m
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

#import "DockIconController.h"
#import "iChat5.h"
#import "ChaxDockView.h"

static DockIconController *_sharedController = nil;

@implementation DockIconController

+ (DockIconController *)sharedController
{
	if (!_sharedController) {
		_sharedController = [[DockIconController alloc] init];
	}
	return _sharedController;
}

- (id)init
{
	if ( (self = [super init]) ) {
		_dockView = [[ChaxDockView alloc] initWithFrame:NSMakeRect(0, 0, 128, 128)];
		_chats = [[NSMutableArray alloc] init];
		_flashTimer = nil;
		_chatIndex = 0;
	}
	return self;
}

- (void)dealloc
{
	[_dockView release];
	[_chats release];
	[super dealloc];
}

- (void)addChat:(Chat *)chat
{
	if (![_chats containsObject:chat] && ([Chax boolForKey:@"UseBuddyIconNotification"] || [Chax boolForKey:@"ShowNamesInDock"])) {
		[_chats addObject:chat];
		
		_chatIndex = [_chats count] - 1;
		
		if (!_flashTimer) {
			[[NSApp dockTile] setContentView:_dockView];
			[self updateDockIcon];
			
			_flashTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDockIcon) userInfo:nil repeats:YES];
		}
	}
}

- (void)removeChat:(Chat *)chat
{
	[_chats removeObject:chat];
	
	if ([_chats count] == 0) {
        [[NSApp dockTile] setContentView:nil];
        
		[_flashTimer invalidate], _flashTimer = nil;
	}
}

- (NSArray *)chats
{
	return _chats;
}

- (void)updateDockIcon
{
	//Loop through all the chats to make sure they're still valid
	for (int i = 0; i < [_chats count]; i++) {
		ActiveChat *chat = [_chats objectAtIndex:i];
		
		if (![chat isActive] || ![chat hasUnreadMessages]) {
			[self removeChat:chat];
			i--;
		}
	}
	
	if ([_chats count] > 0) {
		_chatIndex++;
		_chatIndex %= [_chats count] + 1;
		
		if (_chatIndex < [_chats count]) {
			ActiveChat *chat = [_chats objectAtIndex:_chatIndex];
			[_dockView setImage:[[chat otherIMHandle] image]];
		} else {
			[_dockView setImage:nil];
		}
		
		[[NSApp dockTile] display];
	}
}

@end
