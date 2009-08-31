/*
 * ActivityWindowController.h
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

#import <Cocoa/Cocoa.h>

@class ActivityTableView, Presentity;

@interface ActivityWindowController : NSWindowController <NSToolbarDelegate>
{
	IBOutlet NSArrayController *_arrayController;
	IBOutlet NSPopUpButton *_autoclearPopUp;
	IBOutlet NSSearchField *_searchField;
    IBOutlet ActivityTableView *_tableView;
	
	NSArray *_sortDescriptors;
	
	NSToolbar *_toolbar;
	NSManagedObjectContext *_managedObjectContext;
	NSDate *_lastSaveDate;
	
	NSMutableSet *_recentActivity;
    
    BOOL _terminationDisabled;
}
+ (ActivityWindowController *)sharedController;

- (void)addPresentityToActivity:(Presentity *)presentity;

- (NSString *)applicationSupportFolder;
- (NSManagedObjectContext *)managedObjectContext;
@end