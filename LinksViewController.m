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

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    return (selector != @selector(jumpToMessageGUID:inLogAtPath:));
}

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
    
    [[(WebView *)[self view] preferences] setJavaScriptEnabled:YES];
}

- (void)jumpToMessageGUID:(NSString *)messageGUID inLogAtPath:(NSString *)logPath
{
    [[LogViewerController sharedController] jumpToMessageGUID:messageGUID inLogAtPath:logPath];
}

- (void)updateWithSavedChatPaths:(NSArray *)savedChatPaths
{
    WebView *webView = (WebView *)[self view];
    NSMutableString *htmlString = [[[NSMutableString alloc] initWithString:@"<html><head>\n"] autorelease];
    
    [htmlString appendString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"logviewer.css\"/>\n"];
    [htmlString appendString:@"<script type=\"text/javascript\">\n"];
    [htmlString appendString:@"var linksViewController; function jumpToMessage(guid, logPath) { linksViewController.jumpToMessageGUID_inLogAtPath_(guid, logPath); }\n"];
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
            __block NSUInteger linkCount = 0;
            
            [htmlString appendFormat:@"<div id=\"%@\" class=\"transcript links\">", nextSavedChatPath];
            [htmlString appendFormat:@"<h2>%@</h2>", headingString];
            
            for (InstantMessage *msg in [chat messages]) {
                //Add a line for each URL
                [[msg text] enumerateAttribute:@"IMLinkAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                    if (value) {
                        [htmlString appendFormat:@"<div class=\"transcript_link\" id=\"%@\">", [msg guid]];
                        [htmlString appendFormat:@"<div class=\"jump_to_conversation_link\" title=\"%@\" onclick=\"jumpToMessage('%@', '%@'); event.cancelBubble=true;\"></div>", ChaxLocalizedString(@"Show link in transcript"), [msg guid], nextSavedChatPath];
                        [htmlString appendFormat:@"%@: <a href=\"%@\">%@</a>", [(IMHandle *)[msg sender] name], value, value];
                        [htmlString appendString:@"</div>\n"];
                        
                        linkCount++;
                    }
                }];
            }
            
            //If there were no links in the log, write no logs
            if (linkCount == 0) {
                [htmlString appendFormat:@"<p class=\"no_items\">%@</p>\n", ChaxLocalizedString(@"No links in transcript.")];
            }
            
            [htmlString appendString:@"<div class=\"spacer\"></div>"];
            [htmlString appendString:@"</div>"];
        }
        
        [htmlString appendString:@"<div class=\"spacer\"></div>"];
        [htmlString appendString:@"</body></html>"];
        
        [[webView mainFrame] loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:TemporaryImagePath()]];
        
        [pool release];
    }
    
    [[(WebView *)[self view] preferences] setJavaScriptEnabled:YES]; //I wish I knew why JavaScript insists on turning itself off over and over
}

#pragma mark -
#pragma mark WebView Frame Load Delegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"linksViewController"];
}

#pragma mark -
#pragma mark WebView Policy Delegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeLinkClicked) {
        [listener ignore];
        
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    } else {
        [listener use];
    }
}

#pragma mark -
#pragma mark WebView Resource Load Delegate

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    NSString *lastPathComponent = [[[request URL] path] lastPathComponent];
    
    if ([lastPathComponent isEqualToString:@"ChaxArrow.tiff"]) {
        request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[LogViewerController arrowPath]]];
    } else if ([lastPathComponent isEqualToString:@"ChaxSelectedArrow.tiff"]) {
        request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:[LogViewerController selectedArrowPath]]];
    } else if ([lastPathComponent isEqualToString:@"logviewer.css"]) {
        NSString *cssPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForResource:[lastPathComponent stringByDeletingPathExtension] ofType:[lastPathComponent pathExtension]];
        
        request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:cssPath]];
    }
    
    return request;
}

#pragma mark -
#pragma mark WebView UI Delegate

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    for (NSMenuItem *item in defaultMenuItems) {
        //2000 is Open Link. It doesn't appear to have a public tag constant.
        if ([item tag] == WebMenuItemTagCopyLinkToClipboard || [item tag] == 2000) {
            [menuItems addObject:item];
        }
    }
    
    return menuItems;
}

@end
