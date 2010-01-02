/*
 * AutoAcceptPrefsWindowController.m
 *
 * Copyright (c) 2007- Kent Sutherland
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

#import "AutoAcceptPrefsWindowController.h"
#import "iChat5.h"
#import "Chax.h"

enum {
	AutoAcceptFiles = 1,
	AutoAcceptAVChats,
	AutoAcceptScreenSharing
};

@implementation AutoAcceptPrefsWindowController

- (id)init
{
	if ([super init]) {
		_services = [[NSMutableArray alloc] init];
		_contacts = [[NSMutableDictionary alloc] init];
		_autoAcceptDictionary = nil;
		_allContactsString = [[NSAttributedString alloc] initWithString:ChaxLocalizedString(@"Anyone") attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.10] forKey:NSObliquenessAttributeName]];
	}
	return self;
}

- (void)dealloc
{
	[_services release];
	[_contacts release];
	[_autoAcceptDictionary release];
	[_allContactsString release];
	[super dealloc];
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:[self window]];
	[self close];
}

- (IBAction)save:(id)sender
{
	[NSApp endSheet:[self window]];
	[Chax setObject:_autoAcceptDictionary forKey:[NSString stringWithFormat:@"AutoAccept.%@", _typeName]];
	[self close];
	
	[_autoAcceptDictionary release], _autoAcceptDictionary = nil;
}

- (void)setAutoAcceptType:(int)type
{
	_type = type;
	
	[self willChangeValueForKey:@"autoAcceptFrom"];
	
	switch (type) {
		case 1:
			_typeName = @"Files";
			[_descriptionTextField setStringValue:ChaxLocalizedString(@"Auto-accept files from:")];
			break;
		case 2:
			_typeName = @"AVChats";
			[_descriptionTextField setStringValue:ChaxLocalizedString(@"Auto-accept AV chats from:")];
			break;
		case 3:
			_typeName = @"ScreenSharing";
			[_descriptionTextField setStringValue:ChaxLocalizedString(@"Auto-accept screen sharing from:")];
			break;
	}
	
	[self didChangeValueForKey:@"autoAcceptFrom"];
	
	_autoAcceptDictionary = [[Chax objectForKey:[NSString stringWithFormat:@"AutoAccept.%@", _typeName]] mutableCopy];
	
	if (!_autoAcceptDictionary) {
		_autoAcceptDictionary = [[NSMutableDictionary alloc] init];
	}
	
	[_services removeAllObjects];
	
	//Load the presentities for each service
	NSArray *controllers = [NSClassFromString(@"PeopleListController") peopleListControllers];
	
	//May need to skip Bonjour contacts
	for (PeopleListController *pl in controllers) {
		if (![[pl prefIdentifier] isEqualToString:@"Chax"]) {
			NSMutableArray *contacts = [NSMutableArray array];
			NSArray *people = [[pl sourcePeople] people];
            
			[_services addObject:pl];
			
			for (IMHandle *nextHandle in people) {
				if (![contacts containsObject:[nextHandle bestIMHandleForAccount:[pl representedAccount]]]) {
					[contacts addObject:[nextHandle bestIMHandleForAccount:[pl representedAccount]]];
				}
			}
			
			[contacts sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
			[_contacts setObject:contacts forKey:[pl name]];
		}
	}
	
	[_services sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"representedAccount.description" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
	
	[_outlineView reloadData];
}

- (int)autoAcceptFrom
{
	return [Chax integerForKey:[NSString stringWithFormat:@"AutoAcceptSelect.%@", _typeName]];
}

- (void)setAutoAcceptFrom:(int)value
{
	[Chax setInteger:value forKey:[NSString stringWithFormat:@"AutoAcceptSelect.%@", _typeName]];
}

#pragma mark -
#pragma mark NSOutlineView Data Source/Delegate
#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) {
		return [_services count];
	}
	
	return [(NSArray *)[_contacts objectForKey:[(Service *)item name]] count] + 1;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [item isEqual:NSClassFromString(@"Service")] || [item isKindOfClass:NSClassFromString(@"PeopleListController")];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil) {
		return [_services objectAtIndex:index];
	} else if (index == 0) {
		return _allContactsString;
	} else {
		return [[_contacts objectForKey:[(IMHandle *)item name]] objectAtIndex:index - 1];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSCellStateValue state = NSOffState;
	
	if ([outlineView levelForItem:item] > 0) {
		//Get the auto-accept settings for the service
		NSString *serviceID = [(Account *)[[outlineView parentForItem:item] representedAccount] uniqueID];
		NSArray *serviceAutoAccepts = [_autoAcceptDictionary objectForKey:serviceID];
		
		if ([item isKindOfClass:NSClassFromString(@"IMHandle")]) {
			NSArray *siblings = [item siblings];
			
			state = NSOnState;
			
			//Only enable if all the siblings in the presentity are found
			for (Presentity *p in siblings) {
				NSString *ID = [p ID];
				
				if (![serviceAutoAccepts containsObject:ID]) {
					state = NSOffState;
					break;
				}
			}
		} else {
			state = [serviceAutoAccepts containsObject:@"Chax_AcceptAnyone"] ? NSOnState : NSOffState;
		}
	}
	
	return [NSNumber numberWithInt:state];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([outlineView levelForItem:item] > 0) {
		//Get the auto-accept settings for the service
		NSString *serviceID = [(Account *)[[outlineView parentForItem:item] representedAccount] uniqueID];
		NSMutableArray *serviceAutoAccepts = [[[_autoAcceptDictionary objectForKey:serviceID] mutableCopy] autorelease];
		
		if (!serviceAutoAccepts) {
			serviceAutoAccepts = [NSMutableArray array];
		}
		
		if ([item isKindOfClass:NSClassFromString(@"IMHandle")]) {
			NSArray *siblings = [item siblings];
			
			for (Presentity *p in siblings) {
				NSString *ID = [[p ID] lowercaseString];
				
				if ([object boolValue]) {
					if (![serviceAutoAccepts containsObject:ID]) {
						[serviceAutoAccepts addObject:ID];
					}
				} else {
					[serviceAutoAccepts removeObject:ID];
				}
			}
		} else {
			if ([object boolValue]) {
				if (![serviceAutoAccepts containsObject:@"Chax_AcceptAnyone"]) {
					[serviceAutoAccepts addObject:@"Chax_AcceptAnyone"];
				}
			} else {
				[serviceAutoAccepts removeObject:@"Chax_AcceptAnyone"];
			}
		}
		
		[outlineView reloadItem:[outlineView parentForItem:item]];
		[_autoAcceptDictionary setObject:serviceAutoAccepts forKey:serviceID];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSString *title = item;
	
	if ([item isKindOfClass:NSClassFromString(@"PeopleListController")]) {
		[(NSButtonCell *)cell setImagePosition:NSNoImage];
		
		title = [[item representedAccount] description];
		
		if ([(NSArray *)[_autoAcceptDictionary objectForKey:[(Account *)[item representedAccount] uniqueID]] count] > 0) {
			[cell setAttributedTitle:[[[NSAttributedString alloc] initWithString:title attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:13.0f] forKey:NSFontAttributeName]] autorelease]];
		} else {
			[cell setTitle:title];
		}
	} else {
		if ([item isKindOfClass:NSClassFromString(@"IMHandle")]) {
			title = [(IMHandle *)item name];
		}
		
		[(NSButtonCell *)cell setImagePosition:NSImageLeft];
		[cell setTitle:title];
	}
}

@end
