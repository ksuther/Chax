//
//  LogViewerController.h
//  Chax
//
//  Created by Kent Sutherland on 8/10/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FezWebView, ChatViewController;

@interface LogViewerController : NSWindowController {
    IBOutlet ChatViewController *_chatViewController;
    IBOutlet FezWebView *_webView;
    IBOutlet NSTableView *_logsTableView;
    IBOutlet NSTableView *_peopleTableView;
    IBOutlet NSProgressIndicator *_progressIndicator;
    IBOutlet NSTextField *_statusTextField;
    
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

- (IBAction)toolbarAction:(id)sender;

@end
