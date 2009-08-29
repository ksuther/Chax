//
//  ActivityTableView.m
//  Chax
//
//  Created by Kent Sutherland on 6/22/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import "ActivityTableView.h"

@implementation ActivityTableView

- (void)keyDown:(NSEvent *)event
{
    if ([[event characters] characterAtIndex:0] == NSDeleteCharacter || [[event characters] characterAtIndex:0] == NSDeleteCharFunctionKey || [[event characters] characterAtIndex:0] == NSDeleteFunctionKey) {
        if ([self.delegate respondsToSelector:@selector(deleteKeyPressedInTableView:)]) {
			[(NSObject *)self.delegate deleteKeyPressedInTableView:self];
		}
    } else {
        [super keyDown:event];
    }
}

@end
