/*
 * Prefs_Chax.h
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

#import <Cocoa/Cocoa.h>
#import "NSPreferences.h"

@class ChaxDefaults, URLTextView, AutoAcceptPrefsWindowController;

@interface Prefs_Chax : NSPreferencesModule {
    IBOutlet AutoAcceptPrefsWindowController *_autoAcceptPrefs;
    IBOutlet NSView *_view;
    IBOutlet URLTextView *_urlTextView;
    
    IBOutlet NSButton *_checkForUpdatesButton;
    IBOutlet NSButton *_checkForUpdatesCheckbox;
    IBOutlet NSButton *_donateButton;
    
    ChaxDefaults *_defaults;
    
    NSUInteger _editedFont;
    NSFont *_contactsFont;
    NSFont *_statusMessagesFont;
}

@property(nonatomic, retain) NSFont *contactsFont;
@property(nonatomic, retain) NSFont *statusMessagesFont;
@property(nonatomic, retain) NSFont *currentContactFont;

- (void)performLocalizationUICorrections;

- (IBAction)aboutAction:(id)sender;
- (IBAction)changeContactListFont:(id)sender;
- (IBAction)showAutoAcceptOptions:(id)sender;

@end
