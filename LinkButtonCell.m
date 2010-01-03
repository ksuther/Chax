/*
 * LinkButtonCell.m
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

#import "LinkButtonCell.h"
#import "LogViewerController.h"

@implementation LinkButtonCell

@synthesize attachment = _attachment;
@synthesize instantMessage = _instantMessage;
@synthesize chatPath = _chatPath;

- (id)initWithInstantMessage:(InstantMessage *)instantMessage
{
    if ( (self = [self initImageCell:[[[NSImage alloc] initWithContentsOfFile:[LogViewerController arrowPath]] autorelease]]) ) {
        [self setButtonType:NSToggleButton];
        [self setBezelStyle:NSRegularSquareBezelStyle];
        [self setBordered:NO];
        
        [self setAlternateImage:[[[NSImage alloc] initWithContentsOfFile:[LogViewerController selectedArrowPath]] autorelease]];
        
        [self setInstantMessage:instantMessage];
    }
    return self;
}

- (void)dealloc
{
    [_attachment release];
    [_instantMessage release];
    
    [super dealloc];
}

- (NSPoint)cellBaselineOffset
{
    return NSMakePoint(0, 0);
}

- (BOOL)wantsToTrackMouse
{
    return YES;
}

#pragma mark -
#pragma mark Sophisticated Methods

/*- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)view
{
    NSLog(@"rawr %d", flag);
    [self setState:flag ? NSOnState : NSOffState];
}*/

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex
{
    [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
    [super drawWithFrame:cellFrame inView:controlView];
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex untilMouseUp:(BOOL)flag
{
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
    
    [self setState:NSOnState];
    [controlView setNeedsDisplay:YES];
    
    while (keepOn) {
        event = [[controlView window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        mouseLoc = [controlView convertPoint:[event locationInWindow] fromView:nil];
        isInside = [controlView mouse:mouseLoc inRect:cellFrame];
        
        switch ([event type]) {
            case NSLeftMouseDragged:
                [self setState:isInside ? NSOnState : NSOffState];
                break;
            case NSLeftMouseUp:
                if (isInside && [controlView isKindOfClass:[NSTextView class]] && [[(NSTextView *)controlView delegate] respondsToSelector:@selector(textView:clickedOnCell:inRect:atIndex:)]) {
                    [[(NSTextView *)controlView delegate] textView:(NSTextView *)controlView clickedOnCell:self inRect:cellFrame atIndex:charIndex];
                }
                
                [self setState:NSOffState];
                keepOn = NO;
                break;
            default:
                break;
        }
        
        [controlView setNeedsDisplay:YES];
    }
    
    return NO;
}

/*- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)textView untilMouseUp:(BOOL)flag
{
}*/

- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex
{
    return [self wantsToTrackMouse];
}

- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex
{
    return NSMakeRect(0, 0, [self cellSize].width, [self cellSize].height);
}

@end
