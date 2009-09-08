/*
 * ActivityStatusCell.m
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

#import "ActivityStatusCell.h"
#import <InstantMessage/IMService.h>

#define DOCUMENT_ICON @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"

static NSDictionary *_images;

@implementation ActivityStatusCell

- (id)init
{
	if ( (self = [super init]) ) {
		if (_images == nil) {
			NSImage *document = [[NSImage alloc] initByReferencingFile:DOCUMENT_ICON];
			[document setScalesWhenResized:YES];
			[document setSize:NSMakeSize(13, 13)];
			
			_images = [[NSDictionary alloc] initWithObjectsAndKeys:[NSImage imageNamed:[IMService imageNameForStatus:IMPersonStatusUnknown]], [NSNumber numberWithInt:IMPersonStatusUnknown],
														[[[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForImageResource:@"status-offline"]] autorelease], [NSNumber numberWithInt:IMPersonStatusOffline],
														[NSImage imageNamed:[IMService imageNameForStatus:IMPersonStatusIdle]], [NSNumber numberWithInt:IMPersonStatusIdle],
														[NSImage imageNamed:[IMService imageNameForStatus:IMPersonStatusAway]], [NSNumber numberWithInt:IMPersonStatusAway],
														[NSImage imageNamed:[IMService imageNameForStatus:IMPersonStatusAvailable]], [NSNumber numberWithInt:IMPersonStatusAvailable],
														document, [NSNumber numberWithInt:101],
														[document autorelease], [NSNumber numberWithInt:102],
														nil, nil];
		}
	}
	return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage *image = [_images objectForKey:[NSNumber numberWithInt:[[self objectValue] intValue]]];
	[controlView lockFocus];
	[image compositeToPoint:NSMakePoint(cellFrame.origin.x + (cellFrame.size.width - [image size].width) / 2, cellFrame.origin.y + (cellFrame.size.height + [image size].height) / 2) operation:NSCompositeSourceOver];
	[controlView unlockFocus];
}

@end
