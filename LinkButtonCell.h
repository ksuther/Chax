//
//  LinkButtonCell.h
//  Chax
//
//  Created by Kent Sutherland on 12/25/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iChat5.h"

@interface LinkButtonCell : NSButtonCell <NSTextAttachmentCell> {
    NSTextAttachment *_attachment;
    InstantMessage *_instantMessage;
}

@property(retain) NSTextAttachment *attachment;
@property(retain) InstantMessage *instantMessage;

- (id)initWithInstantMessage:(InstantMessage *)instantMessage;

@end
