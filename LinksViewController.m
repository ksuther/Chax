/*
 * LinksViewController.m
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

#import "LinksViewController.h"
#import "LogViewerController.h"
#import "LinkButtonCell.h"

@implementation LinksViewController

- (void)dealloc
{
    [_dateFormatter release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}

- (void)updateWithSavedChatPaths:(NSArray *)savedChatPaths
{
    NSTextView *textView = (NSTextView *)[self view];
    NSAttributedString *newline = [[[NSAttributedString alloc] initWithString:@"\n"] autorelease];
    NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    
    [paragraphStyle setParagraphSpacing:4.0];
    
    NSDictionary *headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    
    //Get the links out of the selected logs
    [textView setString:@""];
    
    for (NSString *nextSavedChatPath in savedChatPaths) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        SavedChat *chat = [LogViewerController savedChatAtPath:nextSavedChatPath];
        
        if ([(NSArray *)[chat messages] count] > 0) {
            NSString *headingString = [NSString stringWithFormat:@"%@: %@\n", [chat _otherIMHandleOrChatroom], [_dateFormatter stringFromDate:[chat dateCreated]]];
            NSAttributedString *attributedHeadingString = [[[NSAttributedString alloc] initWithString:headingString attributes:headingAttributes] autorelease];
            __block NSUInteger linkCount = 0;
            
            [[textView textStorage] appendAttributedString:attributedHeadingString];
            
            for (InstantMessage *msg in [chat messages]) {
                //Add a line for each URL
                [[msg text] enumerateAttribute:@"IMLinkAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                    if (value) {
                        NSDictionary *linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, value, NSLinkAttributeName, nil];
                        NSString *senderString = [NSString stringWithFormat:@" %@: ", [(IMHandle *)[msg sender] name]];
                        NSTextAttachment *attachment = [[[NSTextAttachment alloc] initWithFileWrapper:nil] autorelease];
                        LinkButtonCell *linkButtonCell = [[[LinkButtonCell alloc] initWithInstantMessage:msg] autorelease];
                        
                        [linkButtonCell setChatPath:nextSavedChatPath];
                        [attachment setAttachmentCell:linkButtonCell];
                        
                        NSMutableAttributedString *attachmentString = [[[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy] autorelease];
                        
                        [attachmentString addAttribute:NSToolTipAttributeName value:ChaxLocalizedString(@"Show link in transcript") range:NSMakeRange(0, [attachmentString length])];
                        
                        [[textView textStorage] appendAttributedString:attachmentString];
                        [[textView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:senderString] autorelease]];
                        [[textView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", value] attributes:linkAttributes] autorelease]];
                        
                        linkCount++;
                    }
                }];
            }
            
            //If there were no URLs in the log, write no logs
            if (linkCount == 0) {
                NSDictionary *noLinksAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.2], NSObliquenessAttributeName, nil];
                
                [[textView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:[ChaxLocalizedString(@"No links in transcript.") stringByAppendingString:@"\n"] attributes:noLinksAttributes] autorelease]];
            }
            
            [[textView textStorage] appendAttributedString:newline];
        }
        
        [pool release];
    }
    
    if ([[textView textStorage] length] > 0) {
        [[textView textStorage] deleteCharactersInRange:NSMakeRange([[textView textStorage] length] - 1, 1)];
    }
}

#pragma mark -
#pragma mark NSTextView Delegate

- (void)textView:(NSTextView *)textView clickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
    if ([cell isKindOfClass:[LinkButtonCell class]]) {
        [[LogViewerController sharedController] jumpToMessageGUID:[[(LinkButtonCell *)cell instantMessage] guid] inLogAtPath:[(LinkButtonCell *)cell chatPath]];
    }
}

@end
