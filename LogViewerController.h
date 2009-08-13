//
//  LogViewerController.h
//  Chax
//
//  Created by Kent Sutherland on 8/10/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogViewerController : NSWindowController {
    IBOutlet NSTableView *_peopleTableView;
    
    NSOperationQueue *_operationQueue;
    
    NSArray *_people;
    NSMutableDictionary *_logs;
}

@property(nonatomic, retain) NSArray *people;

+ (LogViewerController *)sharedController;

@end
