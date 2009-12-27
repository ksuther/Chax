//
//  LinkButtonCell.m
//  Chax
//
//  Created by Kent Sutherland on 12/25/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import "LinkButtonCell.h"

@implementation LinkButtonCell

@synthesize attachment = _attachment;
@synthesize instantMessage = _instantMessage;

- (id)initWithInstantMessage:(InstantMessage *)instantMessage
{
    if ( (self = [self initImageCell:[NSImage imageNamed:@"LinkIcon"]]) ) {
        [self setButtonType:NSToggleButton];
        [self setBezelStyle:NSRegularSquareBezelStyle];
        [self setBordered:NO];
        
        [self setAlternateImage:[NSImage imageNamed:@"LinkIconSelected"]];
        
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
