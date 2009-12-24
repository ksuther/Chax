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

typedef enum LogViewerToolbarItem {
    LogViewerToolbarItemDelete = 1,
    LogViewerToolbarItemExport,
    LogViewerToolbarItemReveal,
    LogViewerToolbarItemSearch,
} LogViewerToolbarItem;

@interface LogViewerController ()

- (void)_startSpinnerAnimation;
- (void)_stopSpinnerAnimation;

- (void)_loadLogs:(BOOL)firstRun;
- (void)_updateAssociationsWithLogs:(NSDictionary *)logs people:(NSMutableSet *)peopleSet;
- (NSString *)_fullNameForFile:(NSString *)file;
- (NSDate *)_creationDateForLogAtPath:(NSString *)path;
- (void)_updateLogsTableView;
- (void)_updateLogWithCurrentSelection;
- (void)_removeLogsWithIndexSet:(NSIndexSet *)indexSet;

@end

@implementation LogViewerController

@synthesize people = _people;
@synthesize visibleLogs = _visibleLogs;
@synthesize searchPeople = _searchPeople;

+ (LogViewerController *)sharedController
{
    static LogViewerController *sharedController = nil;
    
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
        _searchLogs = [[NSMutableArray alloc] init];
        
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        _searchQueue = [[NSOperationQueue alloc] init];
        [_searchQueue setMaxConcurrentOperationCount:1];
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        _creationDateFormatter = [[NSDateFormatter alloc] init];
        [_creationDateFormatter setDateFormat:@"yyyy-MM-dd HH.mm"];
        
        _deleteImage = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Mail.app"]] pathForImageResource:@"delete.tiff"]];
        [_deleteImage setName:@"MailDelete"];
        
        _exportImage = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"TextEdit.app"]] pathForImageResource:@"txt.icns"]];
        [_exportImage setName:@"TextEditExport"];
        
        _finderImage = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Finder.app"]] pathForImageResource:@"Finder.icns"]];
        [_finderImage setName:@"FinderReveal"];
    }
    return self;
}

- (void)dealloc
{
    [_people release];
    [_visibleLogs release];
    [_logs release];
    [_searchPeople release];
    [_searchLogs release];
    [_creationDateCache release];
    [_operationQueue release];
    [_searchQueue release];
    
    [_dateFormatter release];
    [_creationDateFormatter release];
    
    [_deleteImage release];
    [_exportImage release];
    [_finderImage release];
    
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
        //Bump the status text back to the right initially
        NSRect frame = [_statusTextField frame];
        frame.origin.x = 20;
        [_statusTextField setFrame:frame];
        
        [_operationQueue addOperationWithBlock:^{
            [self _loadLogs:([_people count] == 0)];
        }];
        
        [self _updateLogsTableView];
    }
    
    [super showWindow:sender];
    
    if (![NSClassFromString(@"Prefs") autosaveChats]) {
        NSAlert *loggingDisabledAlert = [[NSAlert alloc] init];
        
        [loggingDisabledAlert setAlertStyle:NSInformationalAlertStyle];
        [loggingDisabledAlert setMessageText:ChaxLocalizedString(@"Logging is disabled")];
        [loggingDisabledAlert setInformativeText:ChaxLocalizedString(@"iChat is not currently logging your conversations, so past conversations will not appear in the log viewer. Go to the Messages tab in the iChat preferences to begin saving your chat transcripts.")];
        [loggingDisabledAlert setIcon:[NSImage imageNamed:@"ChaxIcon"]];
        [loggingDisabledAlert addButtonWithTitle:ChaxLocalizedString(@"OK")];
        [loggingDisabledAlert addButtonWithTitle:ChaxLocalizedString(@"Show Preferences...")];
        [loggingDisabledAlert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(loggingDisabledSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [_creationDateCache removeAllObjects];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL valid = NO;
    
    if ([menuItem action] == @selector(showFindPanel:) || [menuItem action] == @selector(findNext:) || [menuItem action] == @selector(findPrevious:)) {
        valid = ([_logsTableView selectedRow] > -1);
    } else {
        valid = YES;
    }
    
    return valid;
}

- (void)loggingDisabledSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertSecondButtonReturn) {
        [[NSClassFromString(@"FezPreferences") sharedPreferences] showPreferencesPanelForOwner:[NSClassFromString(@"Prefs_MsgCompose") quickSharedInstance]];
    }
}

- (void)confirmDeleteSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
        if ([[self window] firstResponder] == _peopleTableView) {
            NSString *savedChatPath = [NSClassFromString(@"Prefs") savedChatPath];
            NSArray *selectedPeople = [self selectedPeople];
            NSMutableArray *newVisiblePeople = [[[self visiblePeople] mutableCopy] autorelease];
            
            //Delete all logs for the selected people
            for (NSString *nextLog in _visibleLogs) {
                NSString *logPath = [savedChatPath stringByAppendingPathComponent:nextLog];
                NSURL *logURL = [NSURL fileURLWithPath:logPath];
                
                [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:logURL] completionHandler:nil];
            }
            
            for (NSString *nextPerson in selectedPeople) {
                [_logs removeObjectForKey:nextPerson];
                
                [newVisiblePeople removeObject:nextPerson];
            }
            
            [self setVisiblePeople:newVisiblePeople];
            
            [_peopleTableView deselectAll:nil];
            [_peopleTableView reloadData];
            [self _updateLogsTableView];
        } else {
            [self _removeLogsWithIndexSet:[_logsTableView selectedRowIndexes]];
        }
    }
}

#pragma mark -
#pragma mark Properties

- (void)setVisiblePeople:(NSArray *)visiblePeople
{
    if (_searchPeople != nil) {
        [self setSearchPeople:visiblePeople];
    } else {
        [self setPeople:visiblePeople];
    }
}

- (NSArray *)visiblePeople
{
    return (_searchPeople != nil) ? _searchPeople : _people;
}

- (NSArray *)selectedPeople
{
    NSMutableArray *selectedPeople = [NSMutableArray array];
    
    [[_peopleTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        [selectedPeople addObject:[[self visiblePeople] objectAtIndex:idx]];
    }];
    
    return selectedPeople;
}

#pragma mark -
#pragma mark Spotlight Search

- (void)spotlightNotificationReceived:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:_spotlightQuery];
    
	//Extract results out of the query
    NSMutableSet *searchPeopleSet = [NSMutableSet set];
    NSString *logsPath = [NSClassFromString(@"Prefs") savedChatPath];
    NSUInteger logsPathLength = [logsPath length] + 1;
    NSUInteger resultCount = [[note object] resultCount];
    
    [_searchQueue addOperationWithBlock:^{
        [_searchLogs removeAllObjects];
        
        for (NSUInteger i = 0; i < resultCount; i++) {
            NSString *path = [[[note object] resultAtIndex:i] valueForAttribute:@"kMDItemPath"];
            
            path = [path substringFromIndex:logsPathLength];
            
            [_searchLogs addObject:path];
            
            for (NSString *personName in _logs) {
                NSSet *personLogs = [_logs objectForKey:personName];
                
                if ([personLogs containsObject:path]) {
                    [searchPeopleSet addObject:personName];
                    break;
                }
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([note object] == _spotlightQuery) {
                [_spotlightQuery stopQuery];
                [_spotlightQuery autorelease];
                _spotlightQuery = nil;
                
                [self setSearchPeople:[[searchPeopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
                
                [_peopleTableView reloadData];
                
                [_logsTableView deselectAll:nil];
                [self _updateLogsTableView];
                
                //Update the status text and progress indicator
                [self _stopSpinnerAnimation];
                
                if (resultCount == 0) {
                    [_statusTextField setStringValue:ChaxLocalizedString(@"No results")];
                } else if (resultCount == 1) {
                    [_statusTextField setStringValue:ChaxLocalizedString(@"One result")];
                } else {
                    [_statusTextField setStringValue:[NSString stringWithFormat:ChaxLocalizedString(@"%d results"), resultCount]];
                }
            }
        });
    }];
}

#pragma mark -
#pragma mark IBActions

- (IBAction)filterButtonAction:(id)sender
{
    [_conversationButton setState:NSOffState];
    [_fileButton setState:NSOffState];
    [_linkButton setState:NSOffState];
    
    [(NSButton *)sender setState:NSOnState];
}

- (IBAction)toolbarAction:(id)sender
{
    switch ([sender tag]) {
        case LogViewerToolbarItemDelete:
            if (([[self window] firstResponder] == _peopleTableView && [_peopleTableView selectedRow] > -1) || [_logsTableView numberOfSelectedRows] > 1) {
                NSAlert *alert = [NSAlert alertWithMessageText:ChaxLocalizedString(@"Delete Logs") defaultButton:ChaxLocalizedString(@"Delete") alternateButton:ChaxLocalizedString(@"Don't Delete") otherButton:nil informativeTextWithFormat:ChaxLocalizedString(@"Are you sure you want to delete all selected logs?")];
                
                [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\e"];
                
                [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(confirmDeleteSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
            } else {
                [self _removeLogsWithIndexSet:[_logsTableView selectedRowIndexes]];
            }
            break;
        case LogViewerToolbarItemExport:
            {
                NSSavePanel *panel = [NSSavePanel savePanel];
                
                [panel setCanSelectHiddenExtension:YES];
                [panel setCanCreateDirectories:YES];
                [panel setRequiredFileType:@"txt"];
                [panel setNameFieldStringValue:[[_chatViewController chat] defaultSaveName]];
                [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
                    if (result == NSFileHandlingPanelOKButton) {
                        //Get a string representation of the currently selected log
                        NSArray *messages = [[_chatViewController chat] messages];
                        NSMutableString *stringRepresentation = [[NSMutableString alloc] init];
                        
                        for (InstantMessage *message in messages) {
                            NSString *time = [[message time] descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
                            
                            if ([message sender]) {
                                [stringRepresentation appendFormat:@"(%@) %@: %@\n", time, [(IMHandle *)[message sender] name], [[message text] string]];
                            } else if ([message subject]) {
                                [stringRepresentation appendFormat:@"(%@) %@\n", time, [NSString stringWithFormat:[[message text] string], [(IMHandle *)[message subject] name]]];
                            }
                        }
                        
                        [stringRepresentation writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        [stringRepresentation release];
                    }
                }];
            }
            break;
        case LogViewerToolbarItemReveal:
            if ([_logsTableView selectedRow] > -1) {
                NSString *path = [[NSClassFromString(@"Prefs") savedChatPath] stringByAppendingPathComponent:[_visibleLogs objectAtIndex:[_logsTableView selectedRow]]];
                
                [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
            }
            break;
        case LogViewerToolbarItemSearch:
            [[self class] cancelPreviousPerformRequestsWithTarget:self];
            
            if ([sender isKindOfClass:[NSSearchField class]]) {
                [self performSelector:@selector(_beginSpotlightSearch:) withObject:[(NSSearchField *)sender stringValue] afterDelay:0.1];
            } else {
                [self performSelector:@selector(_beginSpotlightSearch:) withObject:[(NSSearchField *)[sender view] stringValue] afterDelay:0.1];
            }
            break;
    }
}

#pragma mark -
#pragma mark Toolbar

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    BOOL valid = NO;
    
    switch ([toolbarItem tag]) {
        case LogViewerToolbarItemDelete:
            valid = ([_peopleTableView selectedRow] > -1);
            break;
        case LogViewerToolbarItemExport:
        case LogViewerToolbarItemReveal:
            valid = ([_logsTableView numberOfSelectedRows] == 1);
            break;
    }
    
    return valid;
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
#pragma mark NSSplitView Delegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    return (splitView == _verticalSplitView) ? 120 : 70;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    return (splitView == _verticalSplitView) ? [splitView bounds].size.width - 300 : [splitView bounds].size.height - 70;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    BOOL shouldAdjust = YES;
    
    //Don't allow the table views to resize when the split view is resized
    if ([view isKindOfClass:[NSScrollView class]]) {
        NSView *documentView = [(NSScrollView *)view documentView];
        
        shouldAdjust = !(documentView == _logsTableView || documentView == _peopleTableView);
    }
    
    return shouldAdjust;
}

#pragma mark -
#pragma mark NSTableView Data Source/Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger numberOfRows;
    
    if (tableView == _peopleTableView) {
        numberOfRows = [[self visiblePeople] count];
    } else {
        numberOfRows = [_visibleLogs count];
    }
    
    return numberOfRows;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id object;
    
    if (tableView == _peopleTableView) {
        object = [[tableColumn identifier] isEqualToString:@"name"] ? [[self visiblePeople] objectAtIndex:row] : @"";
    } else {
        object = [_dateFormatter stringFromDate:[_creationDateCache objectForKey:[_visibleLogs objectAtIndex:row]]];
    }
    
    return object;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == _peopleTableView) {
        [_logsTableView deselectAll:nil];
        
        [self _updateLogsTableView];
    } else if ([notification object] == _logsTableView) {
        [self _updateLogWithCurrentSelection];
    }
}

#pragma mark -
#pragma mark Private

/*
 * Begin the progress indicator animation and move the status text to the right
 */
- (void)_startSpinnerAnimation
{
    NSRect frame = [_statusTextField frame];
    
    frame.origin.x = 20;
    
    [_progressIndicator startAnimation:nil];
    [[_statusTextField animator] setFrame:frame];
}

/*
 * End the progress indicator animation and move the status text to the left
 */
- (void)_stopSpinnerAnimation
{
    NSRect frame = [_statusTextField frame];
    
    frame.origin.x = 2;
    
    [_progressIndicator stopAnimation:nil];
    [[_statusTextField animator] setFrame:frame];
}

- (void)_loadLogs:(BOOL)firstRun
{
    [self _startSpinnerAnimation];
    [_statusTextField setStringValue:ChaxLocalizedString(@"Loading logs...")];
    
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
        
        if (fullName != nil && ![name isEqualToString:fullName]) {
            [peopleAssociations setObject:fullName forKey:name];
        }
    }
    
    //Merge arrays of logs using the more accurate names read from the logs
    for (NSString *key in peopleAssociations) {
        NSString *fullName = [peopleAssociations objectForKey:key];
        
        NSArray *oldLogs = [_logs objectForKey:key];
        NSMutableSet *newLogs = [_logs objectForKey:fullName];
        
        if (newLogs == nil) {
            newLogs = [NSMutableSet set];
            
            [_logs setObject:newLogs forKey:fullName];
        }
        
        [peopleSet addObject:fullName];
        [newLogs addObjectsFromArray:oldLogs];
        
        [_logs removeObjectForKey:key];
        [peopleSet removeObject:key];
    }
    
    [self performSelectorOnMainThread:@selector(_setPeoplePreservingSelection:) withObject:[[peopleSet allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] waitUntilDone:NO];
    
    [self _stopSpinnerAnimation];
    [_statusTextField setStringValue:@""];
}

- (NSString *)_fullNameForFile:(NSString *)file
{
    SavedChat *chat = [[NSClassFromString(@"SavedChat") alloc] initWithTranscriptFile:file];
    NSString *fullName = nil;
    NSString *serviceName = [[chat account] serviceName];
    
    if (serviceName != nil && ![serviceName isEqualToString:@"SubNet"]) {
        fullName = [chat _otherIMHandleOrChatroom];
    }
    
    [chat release];
    
    return fullName;
}

- (NSDate *)_creationDateForLogAtPath:(NSString *)path
{
    NSDate *creationDate = nil;
    
    //Parse the date and time out of the filename - reading directly from the filename is the most correct way of reading logs
    //as it takes the time zone that the chat took place into account. Reading a log's creation date that was written in
    //a difference time zone will give you the wrong time zone offset.
    NSString *dateReadString = [path lastPathComponent];
    NSUInteger location = [dateReadString rangeOfString:@" "].location;
    
    //Reduce the chance that the user's name was formatted like a date
    dateReadString = [dateReadString substringFromIndex:location];
    
    NSString *date = [dateReadString stringByMatching:@"\\d\\d\\d\\d-\\d\\d-\\d\\d"];
    NSString *time = [dateReadString stringByMatching:@" \\d\\d\\.\\d\\d"];
    
    creationDate = [_creationDateFormatter dateFromString:[date stringByAppendingString:time]];
    
    if (creationDate == nil) {
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
    
    [_logsTableView scrollRowToVisible:0];
    
    [[_peopleTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        NSString *personName = [[self visiblePeople] objectAtIndex:idx];
        NSSet *logsForRow = [_logs objectForKey:personName];
        
        [allLogs addObjectsFromArray:[logsForRow allObjects]];
    }];
    
    //Filter logs if there are search results
    if ([_searchLogs count] > 0) {
        NSMutableArray *newAllLogs = [NSMutableArray array];
        
        for (NSString *nextLog in _searchLogs) {
            if ([allLogs containsObject:nextLog]) {
                [newAllLogs addObject:nextLog];
            }
        }
        
        allLogs = newAllLogs;
    }
    
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

- (void)_setPeoplePreservingSelection:(NSArray *)people
{
    NSMutableSet *selectedPersonNames = [NSMutableSet set];
    
    [[_peopleTableView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        NSString *personName = [_people objectAtIndex:idx];
        
        [selectedPersonNames addObject:personName];
    }];
    
    [self setPeople:people];
    
    [_peopleTableView reloadData];
    
    NSMutableIndexSet *newIndexes = [NSMutableIndexSet indexSet];
    
    for (NSString *nextPersonName in selectedPersonNames) {
        NSUInteger index = [_people indexOfObject:nextPersonName];
        
        if (index != NSNotFound) {
            [newIndexes addIndex:index];
        }
    }
    
    [_peopleTableView selectRowIndexes:newIndexes byExtendingSelection:NO];
}

- (void)_beginSpotlightSearch:(NSString *)searchString
{
    [_searchQueue cancelAllOperations];
    
    if ([searchString length] > 0) {
		if (_spotlightQuery) {
			[_spotlightQuery stopQuery];
			[_spotlightQuery autorelease];
		}
		
		//Begin a new search with searchString
		_spotlightQuery = [[NSMetadataQuery alloc] init];
		[_spotlightQuery setSearchScopes:[NSArray arrayWithObject:[NSClassFromString(@"Prefs") savedChatPath]]];
		[_spotlightQuery setPredicate:[NSPredicate predicateWithFormat:@"kMDItemTextContent like[c] %@", searchString]];
		
		if ([_spotlightQuery startQuery]) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spotlightNotificationReceived:) name:NSMetadataQueryDidFinishGatheringNotification object:_spotlightQuery];
		}
        
        [self _startSpinnerAnimation];
        [_statusTextField setStringValue:ChaxLocalizedString(@"Searching...")];
	} else {
		//Stop any current search
		if (_spotlightQuery) {
			[_spotlightQuery stopQuery];
			[_spotlightQuery autorelease];
			_spotlightQuery = nil;
            
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMetadataQueryDidFinishGatheringNotification object:_spotlightQuery];
		}
        
        if ([self searchPeople] != nil) {
            [self setSearchPeople:nil];
            
            [_searchLogs removeAllObjects];
            
            [_peopleTableView deselectAll:nil];
            [_logsTableView deselectAll:nil];
            
            [_peopleTableView reloadData];
            [_logsTableView reloadData];
        }
        
        [self _stopSpinnerAnimation];
        [_statusTextField setStringValue:@""];
	}
}

- (void)_updateLogWithCurrentSelection
{
    NSIndexSet *selectedRowIndexes = [_logsTableView selectedRowIndexes];
    NSString *logPath = [NSClassFromString(@"Prefs") savedChatPath];
    
    if ([selectedRowIndexes count] == 1) {
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
        
        //Get all the links out of the log
        /*for (InstantMessage *msg in [chat messages]) {
            [[msg text] enumerateAttribute:@"IMLinkAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                if (value) {
                    NSLog(@"%@", value);
                }
            }];
            
            [[msg text] enumerateAttribute:@"IMFileTransferGUIDAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                if (value) {
                    NSLog(@"transfer: %@", [[[IMFileTransferCenter sharedInstance] transferForGUID:value includeRemoved:YES] previewItemURL]);
                }
            }];
            
            [[msg text] enumerateAttribute:@"IMFilenameAttributeName" inRange:NSMakeRange(0, [(NSAttributedString *)[msg text] length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop){
                if (value) {
                    NSLog(@"%@", [msg attributedSummaryString]);
                }
            }];
        }*/
    } else if ([_chatViewController chat] != nil) {
        [_chatViewController setChat:nil];
        [_chatViewController loadBaseDocument];
        [_chatViewController _layoutIfNecessary];
    }
}

- (void)_removeLogsWithIndexSet:(NSIndexSet *)indexSet
{
    NSString *savedChatPath = [NSClassFromString(@"Prefs") savedChatPath];
    NSMutableArray *newVisibleLogs = [[_visibleLogs mutableCopy] autorelease];
    NSArray *selectedPeople = [self selectedPeople];
    
    //Delete all selected logs
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        NSString *log = [_visibleLogs objectAtIndex:idx];
        NSString *logPath = [savedChatPath stringByAppendingPathComponent:log];
        NSURL *logURL = [NSURL fileURLWithPath:logPath];
        
        [newVisibleLogs removeObject:log];
        
        for (NSString *nextPerson in selectedPeople) {
            NSMutableSet *logsForPerson = [_logs objectForKey:nextPerson];
            
            [logsForPerson removeObject:log];
        }
        
        [[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:logURL] completionHandler:nil];
    }];
    
    [self setVisibleLogs:newVisibleLogs];
    [_logsTableView reloadData];
    [self _updateLogWithCurrentSelection];
}

@end
