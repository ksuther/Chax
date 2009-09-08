/*
 * ActivityWindowController.m
 *
 * Copyright (c) 2007-2009 Kent Sutherland
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

#import "ActivityWindowController.h"
#import "Chax.h"
#import <InstantMessage/IMService.h>
#import "iChat5.h"
#import "ActivityDateFormatter.h"
#import "ActivityStatusCell.h"
#import "ActivityTableView.h"

const NSTimeInterval kAutosaveInterval = 60;

static ActivityWindowController *_sharedController;

NSString *ClearLogToolbarItemIdentifier = @"ClearLogToolbarItemIdentifier";
NSString *SaveLogToolbarItemIdentifier = @"SaveLogToolbarItemIdentifier";
NSString *AutoClearToolbarItemIdentifier = @"AutoClearToolbarItemIdentifier";
NSString *FilterToolbarItemIdentifier = @"FilterToolbarItemIdentifier";

@interface ActivityWindowController (Private)
- (void)saveDatabase;
@end

@implementation ActivityWindowController

+ (ActivityWindowController *)sharedController
{
	if (!_sharedController) {
		_sharedController = [[ActivityWindowController alloc] initWithWindowNibName:@"ActivityWindow"];
	}
	return _sharedController;
}

- (id)initWithWindowNibName:(NSString *)nibName
{
	if ( (self = [super initWithWindowNibName:nibName]) ) {
		//Check for old ActivityTable NSTableView settings in iChat's plist
		NSArray *activityTableArray = [[NSUserDefaults standardUserDefaults] arrayForKey:@"NSTableView Columns ActivityTable"];
		if (activityTableArray && [activityTableArray count] < 8) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSTableView Columns ActivityTable"];
		}
		
		[self setWindowFrameAutosaveName:@"Activity"];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceNotificationReceived:) name:@"ChaxFileTransferCompleted" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:NSApplicationWillTerminateNotification object:nil];
		[self window];
		
		_toolbar = [[NSToolbar alloc] initWithIdentifier:@"ActivityToolbar"];
		[_toolbar setDelegate:self];
		[_toolbar setAllowsUserCustomization:NO];
		[_toolbar setAutosavesConfiguration:YES];
		[[self window] setToolbar:_toolbar];
		
		[_arrayController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO selector:@selector(compare:)] autorelease]]];
		
		_lastSaveDate = [[NSDate date] retain];
		
		_recentActivity = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_sortDescriptors release];
	[_managedObjectContext release];
	[_lastSaveDate release];
	[_recentActivity release];
	[super dealloc];
}

#pragma mark -
#pragma mark Core Data Methods
#pragma mark -

- (NSString *)applicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Chax"];
}

- (NSManagedObjectContext *)managedObjectContext
{
	if (!_managedObjectContext) {
		NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForResource:@"ActivityModel" ofType:@"mom"]]] autorelease];
		NSPersistentStoreCoordinator *persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel] autorelease];
		
		NSString *applicationSupportFolder = [self applicationSupportFolder];
		if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportFolder isDirectory:NULL]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:NO attributes:nil error:nil];
		}
		
		NSString *oldStorePath = [applicationSupportFolder stringByAppendingPathComponent:@"Activity.chax"];
		NSURL *url = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"Activity.chaxActivity"]];
		NSError *error = nil;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:oldStorePath]) {
			NSURL *oldURL = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"Activity.chax"]];
			id store = [persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:oldURL options:nil error:nil];
			[persistentStoreCoordinator migratePersistentStore:store toURL:url options:nil withType:NSSQLiteStoreType error:&error];
			
			if (!error) {
                [[NSFileManager defaultManager] removeItemAtPath:oldStorePath error:nil];
			} else {
				NSLog(@"Error migrating store: %@", error);
			}
		} else if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
			[[NSApplication sharedApplication] presentError:error];
		}
		
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
	}
	
	return _managedObjectContext;
}

#pragma mark -

- (void)windowDidLoad
{
	NSDateFormatter *formatter = [[ActivityDateFormatter alloc] initWithDateFormat:@"%X" allowNaturalLanguage:YES];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setLocale:[NSLocale currentLocale]];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	
	[_tableView sizeLastColumnToFit];
	[[[_tableView tableColumnWithIdentifier:@"time"] dataCell] setFormatter:[formatter autorelease]];
	[[_tableView tableColumnWithIdentifier:@"status"] setDataCell:[[[ActivityStatusCell alloc] init] autorelease]];
	[super windowDidLoad];
}

- (void)showWindow:(id)sender
{
	[_tableView reloadData];
	[super showWindow:sender];
}

- (void)notificationReceived:(NSNotification *)note
{
	if ([[note name] isEqualToString:NSApplicationWillTerminateNotification]) {
		[self saveDatabase];
	}
}

- (void)serviceNotificationReceived:(NSNotification *)note
{
	if ([[note name] isEqualToString:@"ChaxFileTransferCompleted"]) {
		NSDictionary *userInfo = [note userInfo];
		
		NSManagedObject *event = [NSEntityDescription insertNewObjectForEntityForName:@"IMEvent" inManagedObjectContext:_managedObjectContext];
		[event setValue:[userInfo objectForKey:@"name"] forKey:@"name"];
		[event setValue:[userInfo objectForKey:@"type"] forKey:@"status"];
		[event setValue:[userInfo objectForKey:@"path"] forKey:@"statusMessage"];
		[event setValue:[NSDate date] forKey:@"time"];
		
		[_managedObjectContext processPendingChanges];
	}
}

- (void)addPresentityToActivity:(Presentity *)presentity
{
	NSString *name = [presentity name];
	ABPerson *abPerson = [[presentity person] abPerson];
    
	if ([Chax boolForKey:@"UseNicknames"] && abPerson) {
		NSString *nick = [abPerson valueForProperty:kABNicknameProperty];
		if (nick) {
			name = nick;
		}
	}
	
	NSString *eventIdentifier = [NSString stringWithFormat:@"%@%d", [name lowercaseString], [presentity status]];
	
	if (![_recentActivity containsObject:eventIdentifier]) {
		NSString *statusMessage = [presentity scriptStatusMessage];
        
		if ([statusMessage length] == 0) {
			statusMessage = nil;
		}
		
		NSManagedObject *event = [NSEntityDescription insertNewObjectForEntityForName:@"IMEvent" inManagedObjectContext:_managedObjectContext];
		[event setValue:name forKey:@"name"];
		[event setValue:[NSNumber numberWithInt:[presentity status]] forKey:@"status"];
		[event setValue:statusMessage forKey:@"statusMessage"];
		[event setValue:[NSDate date] forKey:@"time"];
		
		if ([_tableView rectOfRow:[_tableView selectedRow]].origin.y < [[_tableView enclosingScrollView] frame].size.height) {
			[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		}
		
		[_managedObjectContext processPendingChanges];
        
		if ([_lastSaveDate timeIntervalSinceNow] < -kAutosaveInterval) {
			[self saveDatabase];
		} else {
            _terminationDisabled = YES;
            
            [[NSProcessInfo processInfo] disableSuddenTermination];
        }
		
		[_recentActivity addObject:eventIdentifier];
		[_recentActivity performSelector:@selector(removeObject:) withObject:eventIdentifier afterDelay:1.0];
	}
}

- (void)saveDatabase
{
	//Purge old entries if they're older than the specified threshold
	int autoclear = [Chax integerForKey:@"ActivityAutoclear"];
	
	if (autoclear > 0) {
		NSDate *date;
		
		switch (autoclear) {
			case 1:
				date = [NSDate dateWithTimeIntervalSinceNow:-86400];
				break;
			case 2:
				date = [NSDate dateWithTimeIntervalSinceNow:-604800];
				break;
			case 3:
				date = [NSDate dateWithTimeIntervalSinceNow:-2678400];
				break;
		}
		
		//clear entries before the given date
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:[[[[[self managedObjectContext] persistentStoreCoordinator] managedObjectModel] entitiesByName] objectForKey:@"IMEvent"]];
		[fetchRequest setPredicate:[NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"time"] rightExpression:[NSExpression expressionForConstantValue:date] modifier:NSLessThanPredicateOperatorType type:NSDirectPredicateModifier options:0]];
		NSEnumerator *resultsEnumerator = [[[self managedObjectContext] executeFetchRequest:fetchRequest error:nil] objectEnumerator];
		NSManagedObject *nextResult;
		
		while ( (nextResult = [resultsEnumerator nextObject]) ) {
			[[self managedObjectContext] deleteObject:nextResult];
		}
	}
	
	[_lastSaveDate release];
	_lastSaveDate = [[NSDate date] retain];
	[_managedObjectContext save:nil];
	
    if (_terminationDisabled) {
        _terminationDisabled = NO;
        
        [[NSProcessInfo processInfo] enableSuddenTermination];
    }
}

#pragma mark -
#pragma mark - NSTableView Delegate Methods
#pragma mark -

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	NSString *value = nil;
	if (row > -1) {
		NSManagedObject *item = [[_arrayController arrangedObjects] objectAtIndex:row];
		if ([item valueForKey:@"statusMessage"]) {
			int status = [[item valueForKey:@"status"] intValue];
			NSString *statusString;
			
			switch (status) {
				case 101:
					statusString = ChaxLocalizedString(@"Incoming File");
					break;
				case 102:
					statusString = ChaxLocalizedString(@"Outgoing File");
					break;
				default:
					statusString = [NSClassFromString(@"IMHandle") nameOfStatus:status];
					break;
			}
			
			value = [NSString stringWithFormat:@"%@ - %@ - %@", [item valueForKey:@"name"], [item valueForKey:@"statusMessage"], statusString];
		} else {
			value = [NSString stringWithFormat:@"%@ - %@", [item valueForKey:@"name"], [NSClassFromString(@"IMHandle") nameOfStatus:[[item valueForKey:@"status"] intValue]]];
		}
	}
	return value;
}

- (void)tableViewColumnDidResize:(NSNotification *)note
{
	[_tableView performSelector:@selector(sizeLastColumnToFit) withObject:nil afterDelay:0.0];
}

- (void)deleteKeyPressedInTableView:(NSTableView *)tableView
{
	if ([tableView selectedRow] > -1) {
		[_arrayController removeObjectAtArrangedObjectIndex:[tableView selectedRow]];
	}
}

#pragma mark -
#pragma mark Toolbar Delegate Methods
#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
	[item setAction:@selector(toolbarItemAction:)];
	[item setTarget:self];
	
	if ([itemIdentifier isEqualToString:ClearLogToolbarItemIdentifier]) {
		NSImage *clearImage = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"Console.app"]] pathForImageResource:@"Clear.tiff"]];
		[item setLabel:ChaxLocalizedString(@"Clear")];
		[item setImage:clearImage];
		[clearImage release];
	} else if ([itemIdentifier isEqualToString:SaveLogToolbarItemIdentifier]) {
		NSImage *exportImage = [[NSImage alloc] initByReferencingFile:[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"TextEdit.app"]] pathForImageResource:@"txt.icns"]];
		[item setLabel:ChaxLocalizedString(@"Export")];
		[item setImage:exportImage];
		[exportImage release];
	} else if ([itemIdentifier isEqualToString:FilterToolbarItemIdentifier]) {
		[item setLabel:ChaxLocalizedString(@"Filter")];
		[_searchField removeFromSuperview];
		[item setMaxSize:NSMakeSize(150, 22)];
		[item setMinSize:NSMakeSize(50, 22)];
		[item setView:_searchField];
	} else if ([itemIdentifier isEqualToString:AutoClearToolbarItemIdentifier]) {
		[_autoclearPopUp removeFromSuperview];
		[_autoclearPopUp selectItemWithTag:[Chax integerForKey:@"ActivityAutoclear"]];
		[_autoclearPopUp setAction:@selector(toolbarItemAction:)];
		[item setLabel:ChaxLocalizedString(@"Recent Activity Length")];
		[item setMaxSize:NSMakeSize(100, 22)];
		[item setMinSize:NSMakeSize(50, 22)];
		[item setView:_autoclearPopUp];
	} else {
		[item release];
		item = nil;
	}
	
	return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ClearLogToolbarItemIdentifier, SaveLogToolbarItemIdentifier, AutoClearToolbarItemIdentifier, FilterToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:ClearLogToolbarItemIdentifier, SaveLogToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, AutoClearToolbarItemIdentifier, FilterToolbarItemIdentifier, nil];
}

- (void)toolbarItemAction:(id)sender {
	if (sender == _autoclearPopUp) {
		[Chax setInteger:[[sender selectedItem] tag] forKey:@"ActivityAutoclear"];
	} else if ([[sender itemIdentifier] isEqualToString:ClearLogToolbarItemIdentifier]) {
		NSAlert *alert = [NSAlert alertWithMessageText:ChaxLocalizedString(@"Clear Past Activity") defaultButton:ChaxLocalizedString(@"Delete") alternateButton:ChaxLocalizedString(@"Don't Delete") otherButton:nil informativeTextWithFormat:ChaxLocalizedString(@"Are you sure you want to permanently delete all past activity?")];
		
		[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\e"];
		
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(clearSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	} else if ([[sender itemIdentifier] isEqualToString:SaveLogToolbarItemIdentifier]) {
		NSSavePanel *panel = [NSSavePanel savePanel];
		[panel setRequiredFileType:@"html"];
		[panel setCanSelectHiddenExtension:YES];
		[panel beginSheetForDirectory:nil file:ChaxLocalizedString(@"iChat Activity Log") modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == NSOKButton) {
		NSEnumerator *enumerator = [[_arrayController arrangedObjects] objectEnumerator];
		NSManagedObject *nextObject;
		NSMutableString *string = [NSMutableString string];
		NSString *timeString;
		
		[string appendString:@"<table>"];
		
		while ( (nextObject = [enumerator nextObject]) ) {
			timeString = [[nextObject valueForKey:@"time"] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
			
			if ([nextObject valueForKey:@"statusMessage"]) {
				int status = [[nextObject valueForKey:@"status"] intValue];
				NSString *statusString;
				
				switch (status) {
					case 101:
						statusString = ChaxLocalizedString(@"Incoming File");
						break;
					case 102:
						statusString = ChaxLocalizedString(@"Outgoing File");
						break;
					default:
						statusString = [NSClassFromString(@"IMHandle") nameOfStatus:status];
						break;
				}
				
				[string appendFormat:@"<tr><td width=\"175\">%@</td><td>%@</td><td>%@</td><td>%@</td></tr>\n", timeString, [nextObject valueForKey:@"name"], statusString, [nextObject valueForKey:@"statusMessage"]];
			} else {
				[string appendFormat:@"<tr><td width=\"175\">%@</td><td>%@</td><td>%@</td></tr>\n", timeString, [nextObject valueForKey:@"name"], [NSClassFromString(@"IMHandle") nameOfStatus:[[nextObject valueForKey:@"status"] intValue]]];
			}
		}
		
		[string appendString:@"</table>"];
		
		[string writeToFile:[sheet filename] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
}

- (void)clearSheetDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSEnumerator *enumerator = [[_arrayController arrangedObjects] objectEnumerator];
		NSManagedObject *nextObject;
		
		while ( (nextObject = [enumerator nextObject]) ) {
			[_managedObjectContext deleteObject:nextObject];
		}
		
		[self saveDatabase];
	}
}

@end