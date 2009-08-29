/*
 * Prefs_Chax.h
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

#import "Prefs_Chax.h"
#import "ChaxDefaults.h"
#import "AutoAcceptPrefsWindowController.h"
#import "Chax_FezPreferences.h"
#import "iChat5.h"

#define SENDER_STATE ([(NSCell *)sender state] == NSOnState)
#define PREF_STATE(x) [Chax boolForKey:x] ? NSOnState : NSOffState

enum {
    kGeneral_SetContactsFontButton = 101,
    kGeneral_SetStatusMessagesFontButton = 102,
    kAbout_CheckForUpdatesButtonTag = 500,
    kAbout_DonateButtonTag = 501,
};

@implementation Prefs_Chax

@synthesize contactsFont = _contactsFont;
@synthesize statusMessagesFont = _statusMessagesFont;

- (id)init
{
	if ( (self = [super init]) ) {
        _defaults = [[ChaxDefaults alloc] init];
        
        NSData *data = [Chax dataForKey:@"ContactListFont"];
        _contactsFont = (data != nil) ? [[NSUnarchiver unarchiveObjectWithData:data] retain] : [[NSFont fontWithName:@"LucidaGrande" size:12] retain];
        
        data = [Chax dataForKey:@"ContactListStatusFont"];
        _statusMessagesFont = (data != nil) ? [[NSUnarchiver unarchiveObjectWithData:data] retain] : [[NSFont fontWithName:@"LucidaGrande" size:11] retain];
        
        [NSBundle loadNibNamed:@"Preferences" owner:self];
	}
	return self;
}

- (void)dealloc
{
    [_defaults release];
    [_contactsFont release];
    [_statusMessagesFont release];
	[super dealloc];
}

- (void)awakeFromNib
{
    //URL text field attributes
    NSRange attributeRange = NSMakeRange(0, [[_urlTextView string] length]);
    
    [[_urlTextView textStorage] addAttribute:NSLinkAttributeName value:[_urlTextView string] range:attributeRange];
    [[_urlTextView textStorage] addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:attributeRange];
    [[_urlTextView textStorage] addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithBool:YES] range:attributeRange];
    [[_urlTextView textStorage] addAttribute:NSCursorAttributeName value:[NSCursor pointingHandCursor] range:attributeRange];
}

#pragma mark -

- (NSImage *)imageForPreferenceNamed:(NSString *)name
{
	return [NSImage imageNamed:@"ChaxIcon"];
}

- (NSView *)viewForPreferenceNamed:(NSString *)name
{
	return _view;
}

- (BOOL)isResizable
{
    return NO;
}

- (NSSize)minSize
{
	return [_view frame].size;
}

#pragma mark -

- (IBAction)aboutAction:(id)sender
{
    switch ([sender tag]) {
        case kAbout_CheckForUpdatesButtonTag:
            [Chax checkForUpdates];
            break;
        case kAbout_DonateButtonTag:
            [[NSWorkspace sharedWorkspace] openURL:DONATE_URL];
            break;
        default:
            break;
    }
}

- (IBAction)changeContactListFont:(id)sender
{
    NSFont *font = ([sender tag] == kGeneral_SetContactsFontButton) ? _contactsFont : _statusMessagesFont;
    
    _editedFont = [sender tag];
    
    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction)showAutoAcceptOptions:(id)sender
{
	//Load auto-accept settings depending on which button was clicked
	[_autoAcceptPrefs setAutoAcceptType:[sender tag]];
	[NSApp beginSheet:[_autoAcceptPrefs window] modalForWindow:[[NSClassFromString(@"FezPreferences") sharedPreferences] chax_preferencesPanel] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

#pragma mark -
#pragma mark Properties

- (NSString *)contactsFontString
{
    return [NSString stringWithFormat:@"%@ %.0f", [_contactsFont displayName], [_contactsFont pointSize]];
}

- (NSString *)statusMessagesFontString
{
    return [NSString stringWithFormat:@"%@ %.0f", [_statusMessagesFont displayName], [_statusMessagesFont pointSize]];
}

- (NSString *)versionString
{
    return [NSString stringWithFormat:@"Chax %@", [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (void)setCurrentContactFont:(NSFont *)font
{
    if (_editedFont == kGeneral_SetContactsFontButton) {
        [self willChangeValueForKey:@"contactsFontString"];
        [self setContactsFont:font];
        [Chax setObject:[NSArchiver archivedDataWithRootObject:font] forKey:@"ContactListFont"];
        [self didChangeValueForKey:@"contactsFontString"];
    } else {
        [self willChangeValueForKey:@"statusMessagesFontString"];
        [self setStatusMessagesFont:font];
        [Chax setObject:[NSArchiver archivedDataWithRootObject:font] forKey:@"ContactListStatusFont"];
        [self didChangeValueForKey:@"statusMessagesFontString"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadContactList" object:nil];
}

- (NSFont *)currentContactFont
{
    return (_editedFont == kGeneral_SetContactsFontButton) ? _contactsFont : _statusMessagesFont;
}

- (void)setAutoresizeContactList:(BOOL)value
{
	[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoresizeContactList"];
	
	if (value) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadContactList" object:nil];
	}
}

- (BOOL)autoresizeContactList
{
	return [[_defaults valueForKey:@"AutoresizeContactList"] boolValue];
}

- (void)setUseCustomContactListFonts:(BOOL)value
{
	[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"UseCustomContactListFonts"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadContactList" object:nil];
}

- (BOOL)useCustomContactListFonts
{
	return [[_defaults valueForKey:@"UseCustomContactListFonts"] boolValue];
}

- (void)setConfirmBeforeQuit:(BOOL)value
{
    [_defaults setValue:[NSNumber numberWithBool:value] forKey:@"ConfirmQuit"];
    
    if (value) {
        [[NSProcessInfo processInfo] disableSuddenTermination];
    } else {
        [[NSProcessInfo processInfo] enableSuddenTermination];
    }
}

- (BOOL)confirmBeforeQuit
{
    return [[_defaults valueForKey:@"ConfirmQuit"] boolValue];
}

- (void)setAutoAcceptTextInvitations:(BOOL)value
{
	[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"SkipNewMessageNotification"];
	[NSClassFromString(@"Prefs") setKnockKnock:!value];
}

- (BOOL)autoAcceptTextInvitations
{
	return [[_defaults valueForKey:@"SkipNewMessageNotification"] boolValue];
}

- (void)setAutoAcceptFiles:(BOOL)value
{
	if (value) {
		NSBeginAlertSheet(ChaxLocalizedString(@"Automatically Accept File Transfers?"), ChaxLocalizedString(@"No"), ChaxLocalizedString(@"Yes"), nil, [[NSClassFromString(@"FezPreferences") sharedPreferences] chax_preferencesPanel], self, @selector(confirmSheetDidEnd:returnCode:contextInfo:), nil, (void *)1, ChaxLocalizedString(@"Are you sure you want to automatically accept all files that are sent to you? All files are automatically accepted by default. Click \"Options...\" to only accept files from specific users or on specific accounts."));
	} else {
		[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptFiles"];
	}
}

- (BOOL)autoAcceptFiles
{
	return [[_defaults valueForKey:@"AutoAcceptFiles"] boolValue];
}

- (void)setAutoAcceptAVChats:(BOOL)value
{
	if (value) {
		NSBeginAlertSheet(ChaxLocalizedString(@"Automatically Accept File Transfers?"), ChaxLocalizedString(@"No"), ChaxLocalizedString(@"Yes"), nil, [[NSClassFromString(@"FezPreferences") sharedPreferences] chax_preferencesPanel], self, @selector(confirmSheetDidEnd:returnCode:contextInfo:), nil, (void *)2, ChaxLocalizedString(@"Are you sure you want to automatically accept AV chat invitations that are sent to you? All AV chats are automatically accepted by default. Click \"Options...\" to only accept AV chats from specific users or on specific accounts."));
	} else {
		[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptAVChats"];
	}
}

- (BOOL)autoAcceptAVChats
{
	return [[_defaults valueForKey:@"AutoAcceptAVChats"] boolValue];
}

- (void)setAutoAcceptScreenSharing:(BOOL)value
{
	if (value) {
		NSBeginAlertSheet(ChaxLocalizedString(@"Automatically Accept Screen Sharing Invitations?"), ChaxLocalizedString(@"No"), ChaxLocalizedString(@"Yes"), nil, [[NSClassFromString(@"FezPreferences") sharedPreferences] chax_preferencesPanel], self, @selector(confirmSheetDidEnd:returnCode:contextInfo:), nil, (void *)3, ChaxLocalizedString(@"Are you sure you want to automatically accept all screen sharing invitations that are sent to you? All screen sharing invitations are automatically accepted by default. Click \"Options...\" to only accept screen sharing invitations from specific users or on specific accounts."));
	} else {
		[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptScreenSharing"];
	}
}

- (BOOL)autoAcceptScreenSharing
{
	return [[_defaults valueForKey:@"AutoAcceptScreenSharing"] boolValue];
}

#pragma mark -
#pragma mark Sheet Callback

- (void)confirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	BOOL value = (returnCode != NSOKButton);
	
	switch ((int)contextInfo) {
		case 1:
			[self willChangeValueForKey:@"autoAcceptFiles"];
			[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptFiles"];
			[self didChangeValueForKey:@"autoAcceptFiles"];
			break;
		case 2:
			[self willChangeValueForKey:@"autoAcceptAVChats"];
			[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptAVChats"];
			[self didChangeValueForKey:@"autoAcceptAVChats"];
			break;
		case 3:
			[self willChangeValueForKey:@"autoAcceptScreenSharing"];
			[_defaults setValue:[NSNumber numberWithBool:value] forKey:@"AutoAcceptScreenSharing"];
			[self didChangeValueForKey:@"autoAcceptScreenSharing"];
			break;
	}
}

@end
