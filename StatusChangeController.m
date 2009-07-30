/*
 * StatusChangeController.h
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

#import "StatusChangeController.h"
#import "Chax.h"
#import "iChat5.h"
//#import "ActivityWindowController.h"
//#import "Chax_Presentity.h"

NSString *ChaxGrowlNewMessage = @"New message received";
NSString *ChaxGrowlTextInvitation = @"Text invitation received";
NSString *ChaxGrowlUserOffline = @"User went offline";
NSString *ChaxGrowlUserOnline = @"User came online";
NSString *ChaxGrowlUserAway = @"User went away";
NSString *ChaxGrowlUserIdle = @"User went idle";
NSString *ChaxGrowlUserAvailable = @"User became available";

@implementation StatusChangeController

+ (StatusChangeController *)sharedController
{
	static StatusChangeController *_sharedController = nil;
	
	if (!_sharedController) {
		_sharedController = [[StatusChangeController alloc] init];
	}
	
	return _sharedController;
}

- (id)init
{
	if ([super init]) {
		//Register for status change events from iChat
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusNotificationReceived:) name:@"IMHandleStatusChanged" object:nil];
        
		_recentGrowlNotifications = [[NSMutableSet alloc] init];
		_recentStatusChanges = [[NSMutableDictionary alloc] init];
		
		//Load the Growl framework
		if (!NSClassFromString(@"GrowlApplicationBridge")) {
			NSString *frameworkPath = [[[NSBundle bundleWithIdentifier:ChaxBundleIdentifier] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
			NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
            
			if ([framework load]) {
				[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:self];
			} else {
				NSLog(@"Chax: There was an error loading Growl.framework from %@", frameworkPath);
			}
		}
	}
	return self;
}

- (void)dealloc
{
	[_recentGrowlNotifications release];
	[_recentStatusChanges release];
	[super dealloc];
}

- (void)statusNotificationReceived:(NSNotification *)note
{
	Presentity *presentity = [note object];
    
	if ([presentity timeSinceStatusChanged] < 1 && [[presentity account] accountLoginStatus] == 4 && ![[presentity account] justLoggedIn] &&
        [presentity status] != [presentity previousStatus] && [presentity status] != 5 && [presentity person] != [[IMMe me] person]) {
		//Notify the activity window of the change
		//[[ActivityWindowController sharedController] addPresentityToActivity:presentity];
		
		//Check if the person has an active chat and post the status change to the chat window
		/*if ([Chax boolForKey:@"ShowStatusChanges"]) {
			Chat *chat = [ChatWindowController existingChatWithPresentity:presentity];
			
			if (chat && [chat isKindOfClass:[ActiveChat class]]) {
				NSString *statusString = nil;
				
				switch ([presentity status]) {
					case 2: //Idle
						statusString = ChaxLocalizedString(@"idle_status");
						break;
					case 3: //Away
						if ([presentity status] != [presentity previousStatus] && [presentity previousStatus] != 1) {
							if ([[presentity statusMessage] length] == 0) {
								statusString = ChaxLocalizedString(@"away_status");
							} else {
								statusString = [NSString stringWithFormat:ChaxLocalizedString(@"away_status_msg"), @"%@", [presentity chax_strippedStatusMessage]];
							}
						}
						break;
					case 4: //Available
						if ([presentity status] != [presentity previousStatus] && [presentity previousStatus] != 1) {
							if ([[presentity statusMessage] length] == 0) {
								statusString = ChaxLocalizedString(@"available_status");
							} else {
								statusString = [NSString stringWithFormat:ChaxLocalizedString(@"available_status_msg"), @"%@", [presentity chax_strippedStatusMessage]];
							}
						}
						break;
				}
				
				if (statusString && [_recentStatusChanges objectForKey:[presentity ID]] == nil) {
					[(ActiveChat *)chat addAnnouncementString:statusString subject:presentity];
					//[(ActiveChat *)chat addStatusChangeString:statusString subject:presentity];
					
					[_recentStatusChanges setObject:statusString forKey:[presentity ID]];
					[_recentStatusChanges performSelector:@selector(removeObjectForKey:) withObject:[presentity ID] afterDelay:1.0];
				}
			}
		}*/
		
		//Fire a Growl notification for the status change
		if ([Chax boolForKey:@"GrowlEnabled"]) {
			NSString *title, *description, *notification;
			NSString *name = [presentity name];
			
			switch ([presentity status]) {
				case 1: //Offline
					title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went offline"), name];
					description = nil;
					notification = ChaxGrowlUserOffline;
					break;
				case 2: //Idle
					title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went idle"), name];
					description = nil;
					notification = ChaxGrowlUserIdle;
					break;
				case 3: //Away
					title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went away"), name];
					description = [presentity scriptStatusMessage];
					notification = ChaxGrowlUserAway;
					break;
				case 4: //Available
					if ([presentity previousStatus] == 1) {
						title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ came online"), name];
						description = nil;
						notification = ChaxGrowlUserOnline;
					} else {
						title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ became available"), name];
						description = [presentity scriptStatusMessage];
						notification = ChaxGrowlUserAvailable;
					}
					break;
				default:
					return;
			}
			
			[self postGrowlNotificationWithTitle:title description:description notificationName:notification iconData:[[[presentity customPicture] image] TIFFRepresentation] clickContext:[NSDictionary dictionaryWithObject:[presentity guid] forKey:@"IMHandle"]];
		}
	}
}

- (void)postGrowlNotificationWithTitle:(NSString *)title description:(NSString *)description notificationName:(NSString *)noteName iconData:(NSData *)iconData clickContext:(NSDictionary *)clickContext
{
	NSString *notificationIdentifier = [title lowercaseString];
	
	if (description) {
		notificationIdentifier = [notificationIdentifier stringByAppendingString:description];
	}
	
	//Don't display duplicate notifications
	if (![_recentGrowlNotifications containsObject:notificationIdentifier]) {
		[NSClassFromString(@"GrowlApplicationBridge") notifyWithTitle:title description:description notificationName:noteName iconData:iconData priority:0 isSticky:NO clickContext:clickContext];
		[_recentGrowlNotifications addObject:notificationIdentifier];
		[_recentGrowlNotifications performSelector:@selector(removeObject:) withObject:notificationIdentifier afterDelay:1.0];
	}
}

#pragma mark -
#pragma mark Growl Methods
#pragma mark -

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray *notifications = [NSArray arrayWithObjects:ChaxGrowlNewMessage, ChaxGrowlTextInvitation, ChaxGrowlUserOffline, ChaxGrowlUserOnline, ChaxGrowlUserIdle, ChaxGrowlUserAway, ChaxGrowlUserAvailable, nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:notifications, GROWL_NOTIFICATIONS_ALL, notifications, GROWL_NOTIFICATIONS_DEFAULT, nil, nil];
}

- (NSString *)applicationNameForGrowl
{
	return @"Chax";
}

- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
	if (clickContext) {
		[NSApp activateIgnoringOtherApps:YES];
		
		if ([clickContext objectForKey:@"Chat"]) {
			[NSClassFromString(@"ChatWindowController") displayChat:[NSClassFromString(@"ChatWindowController") visibleChatWithID:[clickContext objectForKey:@"Chat"]]];
		} else {
			NSArray *accounts = [[IMAccountController sharedInstance] allConnectedAccounts];
			
			for (IMAccount *account in accounts) {
				IMHandle *handle = [account imHandleForGuid:[clickContext objectForKey:@"IMHandle"]];
				
				if (handle != nil) {
					Chat *chat = [NSClassFromString(@"ChatWindowController") existingChatWithIMHandle:handle];
					
					if (chat != nil) {
						[NSClassFromString(@"ChatWindowController") displayChat:chat];
					} else {
						//There still may be a chat open with the given presentity, but existingChatWithPresentity isn't giving it up
						NSArray *chats = [NSClassFromString(@"Chat") chatList];
						
						for (Chat *nextChat in chats) {
							IMHandle *otherHandle = [nextChat otherIMHandle];
							if ([[otherHandle ID] isEqualToString:[otherHandle ID]] && [otherHandle service] == [otherHandle service]) {
								[NSClassFromString(@"ChatWindowController") displayChat:nextChat];
								return;
							}
						}
						
						[NSClassFromString(@"ChatWindowController") displayChatForIMHandle:handle style:1];
					}
					break;
				}
			}
		}
	}
}

@end
