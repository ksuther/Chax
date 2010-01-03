/*
 * ConversationViewController.m
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

#import "ConversationViewController.h"
#import "LogViewerController.h"
#import "iChat5.h"

@implementation ConversationViewController

- (void)displayLogAtPath:(NSString *)path
{
    SavedChat *chat = [LogViewerController savedChatAtPath:path];
    
    [_chatViewController scrollToBeginningSmoothly:NO];
    [_chatViewController setChat:chat];
    [_chatViewController _layoutIfNecessary];
}

- (void)jumpToMessageGUID:(NSString *)messageGUID inLogAtPath:(NSString *)logPath
{
    //Remove the jump button from the WebView
    DOMElement *jumpElement = [[[(WebView *)[self view] mainFrame] DOMDocument] getElementById:@"jump_to_conversation"];
    
    [[jumpElement parentElement] removeChild:jumpElement];
    
    //Find the actual InstantMessag object from its guid, then jump to it
    SavedChat *chat = [LogViewerController savedChatAtPath:logPath];
    
    for (InstantMessage *nextMessage in [chat messages]) {
        if ([[nextMessage guid] isEqualToString:messageGUID]) {
            [self jumpToInstantMessage:nextMessage inLogAtPath:logPath];
            break;
        }
    }
}

- (void)jumpToInstantMessage:(InstantMessage *)instantMessage inLogAtPath:(NSString *)logPath
{
    [[LogViewerController sharedController] selectConversationFilterButton];
    
    //Multiple logs might be selected, in this case we need to explicitly load the correct log
    if ([_chatViewController chat] == nil) {
        [self displayLogAtPath:logPath];
    }
    
    //Find the frame of the message containing the link
    NSRect messageBounds = [[_chatViewController renderer] rectOfMessage:instantMessage];
    
    if (NSEqualPoints(messageBounds.origin, NSZeroPoint)) {
        //The GUIDs aren't matching, manually search through the messages and find the message
        for (InstantMessage *msg in [[_chatViewController chat] messages]) {
            if ([[instantMessage sender] isEqual:[msg sender]]) {
                if ([[instantMessage text] isEqualToAttributedString:[msg text]]) {
                    messageBounds = [[_chatViewController renderer] rectOfMessage:msg];
                    break;
                } else {
                    NSArray *matchAttachments = [instantMessage inlineAttachmentAttributesArray];
                    NSArray *nextAttachments = [msg inlineAttachmentAttributesArray];
                    
                    //The text doesn't match, but there may be inline images that we can use to compare data
                    if ([matchAttachments count] == [nextAttachments count]) {
                        for (NSUInteger i = 0; i < [matchAttachments count]; i++) {
                            NSDictionary *matchDictionary = [matchAttachments objectAtIndex:i];
                            NSDictionary *nextDictionary = [nextAttachments objectAtIndex:i];
                            
                            NSString *matchPath = [[TemporaryImagePath() stringByAppendingPathComponent:[matchDictionary objectForKey:@"IMFileTransferGUIDAttributeName"]] stringByAppendingPathComponent:[matchDictionary objectForKey:@"IMFilenameAttributeName"]];
                            NSString *nextPath = [[TemporaryImagePath() stringByAppendingPathComponent:[nextDictionary objectForKey:@"IMFileTransferGUIDAttributeName"]] stringByAppendingPathComponent:[nextDictionary objectForKey:@"IMFilenameAttributeName"]];
                            
                            NSData *matchData = [NSData dataWithContentsOfFile:matchPath];
                            NSData *nextData = [NSData dataWithContentsOfFile:nextPath];
                            
                            if ([matchData isEqualToData:nextData]) {
                                messageBounds = [[_chatViewController renderer] rectOfMessage:msg];
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    messageBounds.origin.y += [(WebView *)[self view] frame].size.height - messageBounds.size.height - 12;
    
    //Freakish thing required to get at the actual view we want to scroll
    //ChatViewScrollHelper seems to do it this way, so I'm just copying Apple
    [[[[[[(WebView *)[self view] mainFrame] frameView] documentView] enclosingScrollView] contentView] scrollRectToVisible:messageBounds];
}

#pragma mark -
#pragma mark Find

- (void)showFindPanel:(id)sender
{
	[[NSClassFromString(@"FindPanelController") sharedController] showWindow:sender];
	[[[self view] window] makeFirstResponder:[self view]];
}

- (void)findNext:(id)sender
{
	[(FindPanelController *)[NSClassFromString(@"FindPanelController") sharedController] findNext:sender];
}

- (void)findPrevious:(id)sender
{
	[(FindPanelController *)[NSClassFromString(@"FindPanelController") sharedController] findPrevious:sender];
}

#pragma mark -
#pragma mark Forwarded Chat View Methods

- (void)makeTextBigger:(id)fp8
{
    [_chatViewController makeTextLarger:fp8];
}

- (void)makeTextStandardSize:(id)fp8
{
    [_chatViewController makeTextStandardSize:fp8];
}

- (void)makeTextSmaller:(id)fp8
{
    [_chatViewController makeTextSmaller:fp8];
}

- (void)toggleHideSmileys:(id)fp8
{
    [_chatViewController toggleHideSmileys:fp8];
}

- (void)setChatShowsNames:(id)fp8
{
    [_chatViewController setChatShowsNames:fp8];
}

- (void)setChatShowsPictures:(id)fp8
{
    [_chatViewController setChatShowsPictures:fp8];
}

- (void)setChatShowsNamesAndPictures:(id)fp8
{
    [_chatViewController setChatShowsNamesAndPictures:fp8];
}

- (void)setTranscriptStyleFromMenuItem:(id)fp8
{
    [_chatViewController setTranscriptStyleFromMenuItem:fp8];
}

@end
