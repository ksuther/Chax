//
//  LogViewerModeBackgroundView.m
//  Chax
//
//  Created by Kent Sutherland on 12/23/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import "LogViewerModeBackgroundView.h"

@implementation LogViewerModeBackgroundView

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    bounds = NSInsetRect(bounds, -1, 0);
    
    NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]] autorelease];
    
    [gradient drawInRect:bounds angle:90.0];
    
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];
}

@end
