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

- (void)_loadLogs:(BOOL)firstRun;
- (void)_updateAssociationsWithLogs:(NSDictionary *)logs people:(NSMutableSet *)peopleSet;
- (NSString *)_fullNameForFile:(NSString *)file;
- (NSDate *)_creationDateForLogAtPath:(NSString *)path;
- (void)_updateLogsTableView;

@end

@implementation LogViewerController

@synthesize people = _people;
@synthesize visibleLogs = _visibleLogs;

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
        _creationDateCache = [[NSMutableDictionary alloc] init];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        
        [_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
}

- (void)dealloc
{
    [_people release];
    [_visibleLogs release];
    [_logs release];
    [_creationDateCache release];
    [_operationQueue release];
    [_dateFormatter release];
    
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [_chatViewController willBecomeVisible];
    
    [[self window] center];
}

- (void)showWindow:(id)sender
{
    if (![[self window] isVisible]) {
        [_operationQueue addOperationWithBlock:^{
            [self _loadLogs:([_people count] == 0)];
        }];
        
        [self _updateLogsTableView];
    }
    
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [_creationDateCache removeAllObjects];
}

#pragma mark -
#pragma mark Find

- (void)showFindPanel:(id)sender
{
	[[NSClassFromString(@"FindPanelController") sharedController] showWindow:sender];
	[[self window] makeFirstResponder:_webView];
}

- (void)findNext:(id)sender
{
	[[NSClassFromString(@"FindPanelController") sharedController] findNext:sender];
}

- (void)findPrevious:(id)sender
{
	[[NSClassFromString(@"FindPanelController") sharedController] findPrevious:sender];
}

#pragma mark -
#pragma mark NSTableView Data Source/Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (tableView == _peopleTableView) ? [_people count] : [_visibleLogs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return (tableView == _peopleTableView) ? [_people objectAtIndex:row] : [_dateFormatter stringFromDate:[_creationDateCache objectForKey:[_visibleLogs objectAtIndex:row]]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == _peopleTableView) {
        [_logsTableView deselectAll:nil];
        
        [self _updateLogsTableView];
    } else if ([notification object] == _logsTableView) {
        NSIndexSet *selectedRowIndexes = [_logsTableView selectedRowIndexes];
        NSString *logPath = [NSClassFromString(@"Prefs") savedChatPath];
        
        if ([selectedRowIndexes count] == 0) {
            [_chatViewController setChat:nil];
            [_chatViewController loadBaseDocument];
            [_chatViewController _layoutIfNecessary];
        } else if ([selectedRowIndexes count] == 1) {
            NSString *path = [logPath stringByAppendingPathComponent:[_visibleLogs objectAtIndex:[selectedRowIndexes firstIndex]]];
            SavedChat *chat;
            
            if ([[path pathExtension] isEqualToString:@"ichat"]) {
                chat = [[NSClassFromString(@"SavedChat") alloc] initWithTranscriptFile:path];
            } else {
                NSData *data = [NSData dataWithContentsOfFile:path];
                
                chat = [[NSClassFromString(@"SavedChat") alloc] initWithSavedData:data];
            }
            
            [_chatViewController scrollToBeginningSmoothly:NO];
            [_chatViewController setChat:chat];
            [_chatViewController _layoutIfNecessary];
            
            [chat release];
        } else {
        }
    }
}

#pragma mark -
#pragma mark Private

- (void)_loadLogs:(BOOL)firstRun
{
    NSString *logPath = [NSClassFromString(@"Prefs") savedChatPath];
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
                
                NSMutableSet *personLogs = [_logs objectForKey:name];
                
                if (personLogs == nil) {
                    personLogs = [NSMutableSet set];
                    
                    [_logs setObject:personLogs forKey:name];
                }
                
                [personLogs addObject:nextFile];
            }
        }
    }
    
    if (firstRun) {
        //Only reload the table view if this is the first load, otherwise wait until all the logs have been associated fully
        [self performSelectorOnMainThread:@selector(setPeople:) withObject:[[peopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] waitUntilDone:YES];
        
        [_peopleTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
    
    [self _updateAssociationsWithLogs:logsToScan people:peopleSet];
}

- (void)_updateAssociationsWithLogs:(NSDictionary *)logs people:(NSMutableSet *)peopleSet
{
    NSMutableDictionary *peopleAssociations = [NSMutableDictionary dictionary];
    
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
    
    [self performSelectorOnMainThread:@selector(setPeople:) withObject:[[peopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] waitUntilDone:YES];
    [_peopleTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (NSString *)_fullNameForFile:(NSString *)file
{
    SavedChat *chat = [[NSClassFromString(@"SavedChat") alloc] initWithTranscriptFile:file];
    NSString *fullName = [[chat otherIMHandle] fullName];
    
    [chat release];
    
    return fullName;
}

- (NSDate *)_creationDateForLogAtPath:(NSString *)path
{
    NSDate *creationDate;
    
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    FSRef ref;
    FSCatalogInfo catalogInfo;
    
    CFURLGetFSRef(url, &ref);
    FSGetCatalogInfo(&ref, kFSCatInfoCreateDate, &catalogInfo, nil, NULL, nil);
    
    UTCDateTime createDate = catalogInfo.createDate;
    CFAbsoluteTime absTime;
    
    if (UCConvertUTCDateTimeToCFAbsoluteTime(&createDate, &absTime) == noErr) {
        creationDate = [NSDate dateWithTimeIntervalSinceReferenceDate:absTime];
    } else {
        //Getting creation date failed one way, try the other way
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        
        creationDate = [attributes objectForKey:NSFileCreationDate];
        absTime = [creationDate timeIntervalSinceReferenceDate];
    }
    
    if (absTime < 0) {
        //The creation date on the file is invalid, read it out of the log
        SavedChat *savedChat = nil;
        
        if ([[path pathExtension] isEqualToString:@"ichat"]) {
			savedChat = [[NSClassFromString(@"SavedChat") alloc] initWithTranscriptFile:path];
		} else if ([[path pathExtension] isEqualToString:@"chat"]) {
			NSData *data = [NSData dataWithContentsOfFile:path];
            
			savedChat = [[NSClassFromString(@"SavedChat") alloc] initWithSavedData:data];
		}
        
        creationDate = [savedChat dateCreated];
        
        [savedChat release];
    }
    
    return creationDate;
}

- (void)_updateLogsTableView
{
    NSMutableArray *allLogs = [NSMutableArray array];
    NSString *logPath = [NSClassFromString(@"Prefs") savedChatPath];
    
    [[_peopleTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        NSSet *logsForRow = [_logs objectForKey:[_people objectAtIndex:idx]];
        
        [allLogs addObjectsFromArray:[logsForRow allObjects]];
    }];
    
    //Get the creation date for each of the logs added
    [_operationQueue addOperationWithBlock:^{
        for (NSString *logName in allLogs) {
            NSDate *creationDate = [self _creationDateForLogAtPath:[logPath stringByAppendingPathComponent:logName]];
            
            [_creationDateCache setObject:creationDate forKey:logName];
        }
        
        [allLogs sortUsingComparator:^(id obj1, id obj2){
            NSDate *date1 = [_creationDateCache objectForKey:obj1];
            NSDate *date2 = [_creationDateCache objectForKey:obj2];
            
            //This is backwards, but we we want the most recent logs to appear at the top of the table view
            return [date2 compare:date1];
        }];
        
        [self performSelectorOnMainThread:@selector(setVisibleLogs:) withObject:allLogs waitUntilDone:YES];
        [_logsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}

@end
