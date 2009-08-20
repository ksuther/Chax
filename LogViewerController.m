//
//  LogViewerController.m
//  Chax
//
//  Created by Kent Sutherland on 8/10/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import "LogViewerController.h"
#import "RegexKitLite.h"
#import "iChat5.h"

@interface LogViewerController ()

- (void)_loadLogs;
- (void)_updateAssociationsWithLogs:(NSDictionary *)logs;
- (NSString *)_fullNameForFile:(NSString *)file;

@end

@implementation LogViewerController

@synthesize people = _people;

+ (LogViewerController *)sharedController
{
    LogViewerController *sharedController = nil;
    
	if (sharedController == nil) {
		sharedController = [[LogViewerController alloc] init];
	}
	return sharedController;
}

- (id)init
{
    if ( (self = [super initWithWindowNibName:@"LogViewer"]) ) {
        _logs = [[NSMutableDictionary alloc] init];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        
        [_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    return self;
}

- (void)dealloc
{
    [_people release];
    [_logs release];
    [_operationQueue release];
    
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self window] center];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    
    [_operationQueue addOperationWithBlock:^{
        [self _loadLogs];
    }];
}

#pragma mark -
#pragma mark NSTableView Data Source/Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_people count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [_people objectAtIndex:row];
}

#pragma mark -
#pragma mark Private

- (void)_loadLogs
{
    NSString *logPath = [@"~/Documents/iChats" stringByExpandingTildeInPath];
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:logPath];
    NSString *nextFile;
    NSUInteger count = 0;
    
    //Regular expression that searches for a separator and then a date. This is the format of most logs
	NSString *primaryRegex = @"(?:.*/)?(.*) \\S{1,4} (([0-9]{4}|[0-9]{2}).){3}";
	
	//Fallback expression that searches for just a date or for the French date format
	NSString *secondaryRegex = @"(?:.*/)?(. *)(?: (([0-9]{4}|[0-9]{2}).){3})|(?: \\S{2,3} -(([0-9]{4}|[0-9]{2}).){3})";
    
    NSMutableDictionary *logsToScan = [NSMutableDictionary dictionary];
    
    NSMutableSet *peopleSet = [NSMutableSet set];
    
    while ( (nextFile = [directoryEnumerator nextObject]) ) {
        if ([[nextFile pathExtension] isEqualToString:@"chat"] || [[nextFile pathExtension] isEqualToString:@"ichat"]) {
            count++;
            
            NSString *name = [nextFile stringByMatching:primaryRegex capture:1];
            
			//Search for matches on the log formats
			if (name == nil) {
				//Secondary search
				name = [nextFile stringByMatching:secondaryRegex];
			}
			
			if (name != nil) {
                if (![peopleSet containsObject:name]) {
                    [peopleSet addObject:name];
                    
                    [logsToScan setObject:name forKey:[logPath stringByAppendingPathComponent:nextFile]];
                }
                
                NSMutableArray *personLogs = [_logs objectForKey:name];
                
                if (personLogs == nil) {
                    personLogs = [NSMutableArray array];
                    
                    [_logs setObject:personLogs forKey:name];
                }
                
                [personLogs addObject:nextFile];
            }
        }
    }
    
    [self setPeople:[[peopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    
    [_peopleTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    
    [self _updateAssociationsWithLogs:logsToScan];
}

- (void)_updateAssociationsWithLogs:(NSDictionary *)logs
{
    NSMutableDictionary *peopleAssociations = [NSMutableDictionary dictionary];
    NSMutableSet *peopleSet = [NSMutableSet setWithArray:[self people]];
    
    //Read the current name from the log
    for (NSString *nextFile in logs) {
        NSString *name = [logs objectForKey:nextFile];
        NSString *fullName = [self _fullNameForFile:nextFile];
        
        if (![name isEqualToString:fullName]) {
            [peopleAssociations setObject:fullName forKey:name];
        }
    }
    
    //Merge arrays of logs using the more accurate names read from the logs
    for (NSString *key in peopleAssociations) {
        NSString *fullName = [peopleAssociations objectForKey:key];
        
        NSArray *oldLogs = [_logs objectForKey:key];
        NSMutableArray *newLogs = [_logs objectForKey:fullName];
        
        if (newLogs == nil) {
            newLogs = [NSMutableArray array];
            
            [_logs setObject:newLogs forKey:fullName];
            [peopleSet addObject:fullName];
        }
        
        [newLogs addObjectsFromArray:oldLogs];
        
        [_logs removeObjectForKey:key];
        [peopleSet removeObject:key];
    }
    
    [self setPeople:[[peopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    
    [_peopleTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (NSString *)_fullNameForFile:(NSString *)file
{
    SavedChat *chat = [[NSClassFromString(@"SavedChat") alloc] initWithTranscriptFile:file];
    NSString *fullName = [[chat otherIMHandle] fullName];
    
    [chat release];
    
    return fullName;
}

@end
