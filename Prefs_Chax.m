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

#define SENDER_STATE ([(NSCell *)sender state] == NSOnState)
#define PREF_STATE(x) [Chax boolForKey:x] ? NSOnState : NSOffState

const NSUInteger kGeneral_SetContactsFontButton = 101;
const NSUInteger kGeneral_SetStatusMessagesFontButton = 102;
const NSUInteger kAbout_CheckForUpdatesButtonTag = 500;
const NSUInteger kAbout_DonateButtonTag = 501;

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
        
        _icon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:@"com.ksuther.chax"] pathForImageResource:@"Chax"]];
        
        [NSBundle loadNibNamed:@"Preferences" owner:self];
	}
	return self;
}

- (void)dealloc
{
    [_defaults release];
    [_icon release];
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
	return _icon;
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
            //[[UpdateController sharedController] checkForUpdates:nil];
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

@end
