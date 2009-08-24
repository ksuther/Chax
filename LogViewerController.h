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
    
    NSOperationQueue *_operationQueue;
    
    NSArray *_people;
    NSArray *_visibleLogs;
    NSMutableDictionary *_logs;
    NSMutableDictionary *_creationDateCache;
    
    NSDateFormatter *_dateFormatter;
}

@property(nonatomic, retain) NSArray *people;
@property(nonatomic, retain) NSArray *visibleLogs;

+ (LogViewerController *)sharedController;

@end