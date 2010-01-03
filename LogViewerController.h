/*
 * LogViewerController.h
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@class FezWebView, ChatViewController, SavedChat;
@class ConversationViewController, TransfersViewController, LinksViewController;

@interface LogViewerController : NSWindowController {
    IBOutlet ChatViewController *_chatViewController;
    IBOutlet NSTableView *_logsTableView;
    IBOutlet NSTableView *_peopleTableView;
    
    IBOutlet ConversationViewController *_conversationViewController;
    IBOutlet TransfersViewController *_transfersViewController;
    IBOutlet LinksViewController *_linksViewController;
    
    IBOutlet NSTabView *_logTabView;
    
    IBOutlet NSProgressIndicator *_progressIndicator;
    IBOutlet NSTextField *_statusTextField;
    
    IBOutlet NSSplitView *_horizontalSplitView;
    IBOutlet NSSplitView *_verticalSplitView;
    
    IBOutlet NSButton *_conversationButton;
    IBOutlet NSButton *_fileButton;
    IBOutlet NSButton *_linkButton;
    
    BOOL _transfersNeedUpdate, _linksNeedUpdate;
    
    NSOperationQueue *_operationQueue;
    NSOperationQueue *_searchQueue;
    NSMetadataQuery *_spotlightQuery;
    
    NSArray *_people;
    NSArray *_visibleLogs;
    NSMutableDictionary *_logs;
    NSMutableDictionary *_creationDateCache;
    
    NSArray *_searchPeople;
    NSMutableArray *_searchLogs;
    
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_creationDateFormatter;
    
    NSImage *_deleteImage, *_exportImage, *_finderImage;
}

@property(nonatomic, retain) NSArray *people;
@property(nonatomic, retain) NSArray *visibleLogs;
@property(nonatomic, retain) NSArray *searchPeople;
@property(nonatomic, retain) NSArray *visiblePeople;
@property(nonatomic, readonly) NSArray *selectedPeople;

+ (LogViewerController *)sharedController;

+ (SavedChat *)savedChatAtPath:(NSString *)path;
+ (NSString *)arrowPath;
+ (NSString *)selectedArrowPath;

- (IBAction)filterButtonAction:(id)sender;
- (IBAction)toolbarAction:(id)sender;

- (void)jumpToMessageGUID:(NSString *)messageGUID inLogAtPath:(NSString *)logPath;
- (void)selectConversationFilterButton;

@end
