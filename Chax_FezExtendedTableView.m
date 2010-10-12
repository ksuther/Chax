/*
 * Chax_FezExtendedTableView.m
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

#import "Chax_FezExtendedTableView.h"
#import "LogViewerController.h"
#import "iChat5.h"

@implementation Chax_FezExtendedTableView

#pragma mark -
#pragma mark Added Methods

- (void)chax_menuAction:(id)sender
{
	switch ([sender tag]) {
		case ChaxMenuItemLogViewer:
            {
                NSInteger row = [[sender representedObject] integerValue];
                IMHandle *handle = nil;
                
                [[LogViewerController sharedController] window];
                
                if ([[self delegate] isKindOfClass:NSClassFromString(@"PeopleList")]) {
                    handle = [(PeopleList *)[self delegate] imHandleAtRow:row];
                } else if ([[self delegate] isKindOfClass:NSClassFromString(@"ChatWindowController")]) {
                    handle = [[[self delegate] chatAtIndex:[[sender representedObject] integerValue]] otherIMHandle];
                }
                
                if (handle) {
                    [[LogViewerController sharedController] showLogsForIMHandle:handle];
                }
            }
            break;
	}
}

- (void)chax_popToFront
{
	[[self window] setLevel:NSStatusWindowLevel];
	[[self window] setLevel:NSNormalWindowLevel];
}

#pragma mark -
#pragma mark Swizzled Methods

- (void)chax_swizzle_draggingExited:(id <NSDraggingInfo>)sender
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(chax_popToFront) object:nil];
    
	[self chax_swizzle_draggingExited:sender];
}

- (BOOL)chax_swizzle_performDragOperation:(id)fp8
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(chax_popToFront) object:nil];
    
	return [self chax_swizzle_performDragOperation:fp8];
}

- (NSMenu *)chax_swizzle_menuForEvent:(NSEvent *)event
{
	NSMenu *menu = [self chax_swizzle_menuForEvent:event];
    
	if ([menu numberOfItems] > 15) {
		NSMenuItem *menuItem;
		
		//Remove the previous "Show in Log Viewer" menu items
		menuItem = [menu itemWithTag:ChaxMenuItemLogViewer];
		if (menuItem) {
			[menu removeItem:menuItem];
		}
		
		menuItem = [menu insertItemWithTitle:ChaxLocalizedString(@"Show in Log Viewer") action:@selector(chax_menuAction:) keyEquivalent:@"" atIndex:[menu numberOfItems] - 1];
		[menuItem setTag:ChaxMenuItemLogViewer];
		[menuItem setTarget:self];
		[menuItem setRepresentedObject:[NSNumber numberWithInt:[self _rowAtEventLocation:event]]];
		
		if (![Chax boolForKey:@"HideMenuBadge"]) {
			[menuItem setImage:[NSImage imageNamed:@"ChaxBadge"]];
		}
	}
	return menu;
}

@end
