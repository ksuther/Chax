/*
 * TransfersViewController.m
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

#import "TransfersViewController.h"
#import "iChat5.h"
#import "LogViewerPreviewItem.h"
#import "LogViewerController.h"

@interface TransfersViewController ()
- (NSString *)_meString;
@end

@implementation TransfersViewController

@synthesize imagePaths = _imagePaths;

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    return (selector != @selector(quickLookImageAtIndex:) && selector != @selector(jumpToMessageGUID:inLogAtPath:));
}

#pragma mark -

- (void)dealloc
{
    [_imagePaths release];
    [_dateFormatter release];
    
    [super dealloc];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    [[(WebView *)[self view] preferences] setJavaScriptEnabled:YES];
}

- (void)setImagePaths:(NSArray *)imagePaths
{
    [_imagePaths autorelease];
    _imagePaths = [imagePaths copy];
    
    [_previewPanel reloadData];
}

- (void)quickLookImageAtIndex:(NSInteger)imageIndex
{
    QLPreviewPanel *panel = [QLPreviewPanel sharedPreviewPanel];
    
    _currentImageIndex = imageIndex;
    
    if ([panel currentController]) {
        [panel setCurrentPreviewItemIndex:_currentImageIndex];
    }
    
    [panel makeKeyAndOrderFront:nil];
}

- (void)jumpToMessageGUID:(NSString *)messageGUID inLogAtPath:(NSString *)logPath
{
    [[LogViewerController sharedController] jumpToMessageGUID:messageGUID inLogAtPath:logPath];
}

- (void)updateWithSavedChatPaths:(NSArray *)savedChatPaths
{
    WebView *webView = (WebView *)[self view];
    NSString *logPath = [NSClassFromString(@"Prefs") savedChatPath];
    NSMutableString *htmlString = [[[NSMutableString alloc] initWithString:@"<html><head>\n"] autorelease];
    NSMutableArray *imagePaths = [NSMutableArray array];
    
    [htmlString appendString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"logviewer.css\"/>\n"];
    [htmlString appendString:@"<script type=\"text/javascript\">\n"];
    [htmlString appendString:@"var transfersViewController; function showImage(index) { transfersViewController.quickLookImageAtIndex_(index); }\n"];
    [htmlString appendString:@"function jumpToMessage(guid, logPath) { transfersViewController.jumpToMessageGUID_inLogAtPath_(guid, logPath); }\n"];
    [htmlString appendString:@"</script>\n"];
    [htmlString appendString:@"</head><body>\n"];
    
    if ([savedChatPaths count] == 0) {
        [[webView mainFrame] loadHTMLString:@"" baseURL:nil];
    }
    
    for (NSString *nextSavedChatPath in savedChatPaths) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        SavedChat *chat = [LogViewerController savedChatAtPath:nextSavedChatPath];
        
        if ([(NSArray *)[chat messages] count] > 0) {
            NSString *headingString = [NSString stringWithFormat:@"%@: %@<br />\n", [chat _otherIMHandleOrChatroom], [_dateFormatter stringFromDate:[chat dateCreated]]];
            __block NSUInteger transferCount = 0;
            
            [htmlString appendFormat:@"<div id=\"%@\" class=\"transcript\">", nextSavedChatPath];
            [htmlString appendFormat:@"<h2>%@</h2>", headingString];
            
            for (InstantMessage *msg in [chat messages]) {
                //Add file transfers
                [[msg text] enumerateAttribute:@"IMFileTransferGUIDAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                    if (value) {
                        //Does this have IMFileBookmarkAttributeName associated with it also? If it does, this was a file transfer rather than an inline image
                        NSData *bookmarkData = [[msg text] attribute:@"IMFileBookmarkAttributeName" atIndex:range.location effectiveRange:NULL];
                        NSString *filename = [[msg text] attribute:@"IMFilenameAttributeName" atIndex:range.location effectiveRange:NULL];
                        
                        if (bookmarkData) {
                            //We don't show file transfer anymore, just inline images
                            /*BOOL stale;
                             NSError *error = nil;
                             NSURL *bookmarkURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
                             NSString *filename = [[msg text] attribute:@"IMFilenameAttributeName" atIndex:range.location effectiveRange:NULL];
                             
                             if (bookmarkURL) {
                             filename = [NSString stringWithFormat:@"%@ (%@)", filename, [bookmarkURL path]];
                             }
                             
                             [[_transfersTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:filename] autorelease]];
                             [[_transfersTextView textStorage] appendAttributedString:newline];*/
                        } else {
                            //Build a path to the temporary inline image
                            NSString *imagePath = [value stringByAppendingPathComponent:filename];
                            NSImage *image = [[[NSImage alloc] initByReferencingFile:[TemporaryImagePath() stringByAppendingPathComponent:imagePath]] autorelease];
                            NSSize imageSize = [image size];
                            
                            [htmlString appendFormat:@"<div id=\"%@\" class=\"thumbnail\" onclick=\"showImage('%d')\">", [msg guid], [imagePaths count]];
                            [imagePaths addObject:imagePath];
                            
                            if (imageSize.width > imageSize.height) {
                                [htmlString appendFormat:@"<img id=\"%@\" src=\"%@\" width=\"150\" style=\"margin-top: %.0f\" /><br />", imagePath, imagePath, (150.0f - (150.0f * (imageSize.height / imageSize.width))) / 2.0f];
                            } else {
                                [htmlString appendFormat:@"<img id=\"%@\" src=\"%@\" height=\"150\" /><br />", imagePath, imagePath];
                            }
                            
                            if ([msg fromMe]) {
                                [htmlString appendFormat:@"<div class=\"me\">%@</div>", [self _meString]];
                            }
                            
                            [htmlString appendString:@"</div>\n"];
                            
                            transferCount++;
                        }
                    }
                }];
            }
            
            //If there were no transfers in the log, write no transfers
            if (transferCount == 0) {
                [htmlString appendFormat:@"<p class=\"no_images\">%@</p>\n", ChaxLocalizedString(@"No inline images in transcript.")];
            }
            
            [htmlString appendString:@"<div class=\"spacer\"></div>"];
            [htmlString appendString:@"</div>"];
        }
        
        [htmlString appendString:@"<div class=\"spacer\"></div>"];
        [htmlString appendString:@"</body></html>"];
        
        [[webView mainFrame] loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:TemporaryImagePath()]];
        
        [pool release];
    }
    
    [self setImagePaths:imagePaths];
    
    [[(WebView *)[self view] preferences] setJavaScriptEnabled:YES]; //I wish I knew why JavaScript insists on turning itself off over and over
}

#pragma mark -
#pragma mark Quick Look

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    _previewPanel = [panel retain];
    
    [panel setDataSource:self];
    [panel setDelegate:self];
    
    [panel currentPreviewItemIndex];
    [panel setCurrentPreviewItemIndex:_currentImageIndex];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    [_previewPanel release];
    _previewPanel = nil;
    
    [panel setDataSource:nil];
    [panel setDelegate:nil];
}

#pragma mark -
#pragma mark QLPreviewPanel Data Source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [_imagePaths count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    NSString *path = [TemporaryImagePath() stringByAppendingPathComponent:[_imagePaths objectAtIndex:index]];
    
    return [LogViewerPreviewItem previewItemWithURL:[NSURL fileURLWithPath:path] itemID:[_imagePaths objectAtIndex:index]];
}

#pragma mark -
#pragma mark QLPreviewPanel Delegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    DOMNode *node = [[[(WebView *)[self view] mainFrame] DOMDocument] getElementById:[(LogViewerPreviewItem *)item itemID]];
    NSRect boundingBox = [node boundingBox];
    NSView *docView = [[[[node ownerDocument] webFrame] frameView] documentView];
    
    boundingBox = [docView convertRect:boundingBox toView:nil];
    boundingBox.origin = [[docView window] convertBaseToScreen:boundingBox.origin];
    
    return boundingBox;
}

#pragma mark -
#pragma mark WebView Frame Load Delegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"transfersViewController"];
}

#pragma mark -
#pragma mark WebView Resource Load Delegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    NSString *lastPathComponent = [[[request URL] path] lastPathComponent];
    
    if ([lastPathComponent isEqualToString:@"logviewer.css"] || [lastPathComponent isEqualToString:@"link-icon.tiff"] || [lastPathComponent isEqualToString:@"link-icon-selected.tiff"]) {
        NSString *cssPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForResource:[lastPathComponent stringByDeletingPathExtension] ofType:[lastPathComponent pathExtension]];
        
        request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:cssPath]];
    }
    
    return request;
}

#pragma mark -
#pragma mark WebView UI Delegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSArray *menuItems = nil;
    
    for (NSMenuItem *item in defaultMenuItems) {
        if ([item tag] == WebMenuItemTagCopyImageToClipboard) {
            menuItems = [NSArray arrayWithObject:item];
            break;
        }
    }
    
    return menuItems;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags
{
    DOMElement *node = [elementInformation objectForKey:WebElementDOMNodeKey];
    DOMElement *jumpElement = [[[sender mainFrame] DOMDocument] getElementById:@"jump_to_conversation"];
    
    //Move the 'jump to conversation' button to the current image we're hovering over
    if ([node isKindOfClass:[DOMElement class]]) {
        //Remove the jump button from its current position if necessary
        if (jumpElement && jumpElement != node && [jumpElement parentElement] != node) {
            [[jumpElement parentElement] removeChild:jumpElement];
        }
        
        //We can be hovering over either the inline image div, or a child of the div
        if ([[[node parentElement] getAttribute:@"class"] isEqualToString:@"thumbnail"]) {
            node = [node parentElement];
        } else if (![[node getAttribute:@"class"] isEqualToString:@"thumbnail"]) {
            node = nil;
        }
        
        //Put the jump button in its new spot
        if (node) {
            if (!jumpElement) {
                jumpElement = [[[sender mainFrame] DOMDocument] createElement:@"div"];
                
                [jumpElement setAttribute:@"class" value:@"jump_to_conversation"];
                [jumpElement setAttribute:@"id" value:@"jump_to_conversation"];
                [jumpElement setAttribute:@"title" value:ChaxLocalizedString(@"Show link in transcript")];
            }
            
            NSString *guid = [node getAttribute:@"id"]; //The guid of the InstantMessage to jump to
            NSString *logPath = [[node parentElement] getAttribute:@"id"]; //The file path to the log to jump to
            
            [jumpElement setAttribute:@"onclick" value:[NSString stringWithFormat:@"jumpToMessage('%@', '%@'); event.cancelBubble=true;", guid, logPath]];
            
            [node appendChild:jumpElement];
        }
    }
}

#pragma mark -
#pragma mark Private

- (NSString *)_meString
{
    NSBundle *addressBookFramework = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AddressBook.framework"];
    
    return [addressBookFramework localizedStringForKey:@"ME_LABEL" value:@"me" table:@"ABStrings"];
}

@end
