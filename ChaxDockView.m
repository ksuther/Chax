/*
 * ChaxDockView.m
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

#import "ChaxDockView.h"
#import "DockIconController.h"
#import "iChat5.h"

@implementation ChaxDockView

@synthesize image;

- (id)initWithFrame:(NSRect)frame
{
	if ([super initWithFrame:frame]) {
		invert = NO;
	}
	return self;
}

- (void)drawRect:(NSRect)frame
{
	NSImage *drawImage = [self image];
	
	if (!drawImage || ![Chax boolForKey:@"UseBuddyIconNotification"]) {
		drawImage = [NSImage imageNamed:@"NSApplicationIcon"];
	}
	
	NSSize imageSize = [drawImage size];
	[drawImage drawInRect:[self frame] fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
	
	NSArray *chats = [[DockIconController sharedController] chats];
	
	if ([Chax boolForKey:@"ShowNamesInDock"] && [chats count] > 0) {
		NSColor *foregroundColor = [NSColor whiteColor], *backgroundColor = [NSColor redColor];
		
		invert = [Chax boolForKey:@"FlashBadge"] ? !invert : NO;
		
		if (invert) {
			NSColor *tempColor = foregroundColor;
			foregroundColor = backgroundColor;
			backgroundColor = tempColor;
		}
		
		NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
		
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"LucidaGrande-Bold" size:28], NSFontAttributeName,
																				foregroundColor, NSForegroundColorAttributeName,
																				paragraphStyle, NSParagraphStyleAttributeName, nil];
		
		float drawY = 96;
		
		for (Chat *chat in chats) {
			NSString *chatName = [chat _otherIMHandleOrChatroom];
			
			[backgroundColor set];
            [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, drawY, 128, 32) xRadius:10.0 yRadius:10.0] fill];
			[chatName drawInRect:NSMakeRect(5, drawY + 4, 123, 30) withAttributes:attributes];
			drawY -= 33;
		}
	}
}

@end
