/*
 * Chax_PeopleList.m
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

#import "Chax_PeopleList.h"
#import <objc/runtime.h>

@implementation Chax_PeopleList

#pragma mark -
#pragma mark Added Methods

- (void)chax_updateRowHeights
{
    AnimatingTableView *tableView = [self table];
    
    Ivar ivar = object_getInstanceVariable(self, "_viewOptions", nil);
    unsigned int viewOptions = (NSUInteger)object_getIvar(self, ivar);
    
    //This means showing of buddy pictures is being turned off
    if ((viewOptions & 1) == 1) {
        if ([Chax boolForKey:@"UseCustomContactListFonts"]) {
            NSData *data = [Chax dataForKey:@"ContactListFont"];
            NSFont *font = (data != nil) ? [NSUnarchiver unarchiveObjectWithData:data] : nil;
            
            if (font) {
                CGFloat height = ceilf([font xHeight] + [font ascender] - [font descender]);
                
                [tableView setRowHeight:height];
            }
        } else {
            [tableView setRowHeight:20.0f];
        }
    }
}

#pragma mark -
#pragma mark Swizzled Methods

- (id)chax_swizzle_displayNameForItem:(id)item
{
	if ([Chax boolForKey:@"UseCustomContactListFonts"]) {
		NSData *data = [Chax objectForKey:@"ContactListFont"];
		if (data) {
			NSFont *font = [NSUnarchiver unarchiveObjectWithData:data];
			if (font) {
				NSMutableAttributedString *name = [[[self chax_swizzle_displayNameForItem:item] mutableCopy] autorelease];
				[name addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [[name string] length])];
				return name;
			}
		}
	}
	
	return [self chax_swizzle_displayNameForItem:item];
}

- (id)chax_swizzle_displayStatusForItem:(id)item
{
	if ([[self delegate] isKindOfClass:NSClassFromString(@"PeopleListController")] && [Chax boolForKey:[NSString stringWithFormat:@"%@.HideTextStatus", [[self delegate] prefIdentifier]]]) {
		return [[[NSAttributedString alloc] initWithString:@""] autorelease];
	} else {
		if ([Chax boolForKey:@"UseCustomContactListFonts"]) {
			NSData *data = [Chax objectForKey:@"ContactListStatusFont"];
			if (data) {
				NSFont *font = [NSUnarchiver unarchiveObjectWithData:data];
				if (font) {
					NSMutableAttributedString *message = [[[self chax_swizzle_displayStatusForItem:item] mutableCopy] autorelease];
					[message addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [[message string] length])];
					return message;
				}
			}
		}
		return [self chax_swizzle_displayStatusForItem:item];
	}
}

- (void)chax_swizzle__updateLayout
{
	[self chax_swizzle__updateLayout];
	[self performSelector:@selector(chax_updateRowHeights) withObject:nil afterDelay:0];
}

- (void)chax_swizzle_endChanges
{
	[self chax_swizzle_endChanges];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResizeContactList" object:self];
}

- (void)chax_swizzle_tableView:(id)fp8 groupRowClicked:(int)fp12
{
	[self chax_swizzle_tableView:fp8 groupRowClicked:fp12];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ResizeContactList" object:self];
}

- (NSDragOperation)chax_swizzle_tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([tableView respondsToSelector:@selector(chax_popToFront)]) {
		[tableView performSelector:@selector(chax_popToFront) withObject:nil afterDelay:1.0];
	}
	return [self chax_swizzle_tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:operation];
}

@end
