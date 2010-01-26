/*
 * StatusChangeController.h
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

#import "StatusChangeController.h"
#import "iChat5.h"
#import "ActivityWindowController.h"
#import "Chax_ChatWindowController.h"
#import <InstantMessage/IMService.h>

NSString *ChaxGrowlNewMessage = @"New message received";
NSString *ChaxGrowlTextInvitation = @"Text invitation received";
NSString *ChaxGrowlUserOffline = @"User went offline";
NSString *ChaxGrowlUserOnline = @"User came online";
NSString *ChaxGrowlUserAway = @"User went away";
NSString *ChaxGrowlUserIdle = @"User went idle";
NSString *ChaxGrowlUserAvailable = @"User became available";
NSString *ChaxGrowlUserStatusChanged = @"User changed status message";

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
		_recentGrowlNotifications = [[NSMutableSet alloc] init];
		_recentStatusChanges = [[NSMutableDictionary alloc] init];
		
		//Load the Growl framework
		if (!NSClassFromString(@"GrowlApplicationBridge")) {
			NSString *frameworkPath = [[[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
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

- (void)presentityStatusChanged:(Presentity *)presentity
{
    NSString *statusMessage = [presentity scriptStatusMessage];
    
    ChaxDebugLog(@"presentityStatusChanged: %@ (statusMessage: %@) on contact list: %d timeSinceStatusChanged: %f accountLoginStatus: %d justLoggedIn: %d status: %d previousStatus: %d person: %@ me: %@", presentity, statusMessage, [[[presentity account] arrayOfAllIMHandles] containsObject:presentity], [presentity timeSinceStatusChanged], [[presentity account] accountLoginStatus], [[presentity account] justLoggedIn], [presentity status], [presentity previousStatus], [presentity person], [[IMMe me] person]);
    
	if ([[[presentity account] arrayOfAllIMHandles] containsObject:presentity] && [presentity timeSinceStatusChanged] < 1 && [[presentity account] accountLoginStatus] == 4 && ![[presentity account] justLoggedIn] &&
        [presentity status] != [presentity previousStatus] && [presentity status] != 5 && [presentity person] != [[IMMe me] person]) {
        ChaxDebugLog(@"Person status changed: %@", presentity);
        
		//Notify the activity window of the change
		[[ActivityWindowController sharedController] addPresentityToActivity:presentity];
		
		//Check if the person has an active chat and post the status change to the chat window
		if ([Chax boolForKey:@"ShowStatusChanges"]) {
			Chat *chat = [NSClassFromString(@"ChatWindowController") existingChatWithIMHandle:presentity];
			
			if (chat && [chat isKindOfClass:NSClassFromString(@"ActiveChat")]) {
				NSString *statusString = nil;
				
				switch ([presentity status]) {
					case IMPersonStatusIdle:
						statusString = ChaxLocalizedString(@"%@ went idle.");
						break;
					case IMPersonStatusAway:
						if ([presentity status] != [presentity previousStatus] && [presentity previousStatus] != IMPersonStatusOffline) {
							if ([statusMessage length] == 0) {
								statusString = ChaxLocalizedString(@"%@ went away.");
							} else {
								statusString = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went away. (%@)"), @"%@", statusMessage];
							}
						}
						break;
					case IMPersonStatusAvailable:
						if ([presentity status] != [presentity previousStatus] && [presentity previousStatus] != IMPersonStatusOffline) {
							if ([statusMessage length] == 0) {
								statusString = ChaxLocalizedString(@"%@ became available.");
							} else {
								statusString = [NSString stringWithFormat:ChaxLocalizedString(@"%@ became available. (%@)"), @"%@", statusMessage];
							}
						}
						break;
				}
				
				if (statusString && [_recentStatusChanges objectForKey:[presentity ID]] == nil) {
					[(ActiveChat *)chat addAnnouncementString:statusString subject:presentity];
					
					[_recentStatusChanges setObject:statusString forKey:[presentity ID]];
					[_recentStatusChanges performSelector:@selector(removeObjectForKey:) withObject:[presentity ID] afterDelay:1.0];
				}
			}
		}
		
		//Fire a Growl notification for the status change
        NSString *title, *description, *notification;
        NSString *name = [presentity name];
        
        switch ([presentity status]) {
            case IMPersonStatusOffline:
                title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went offline"), name];
                description = nil;
                notification = ChaxGrowlUserOffline;
                break;
            case IMPersonStatusIdle:
                title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went idle"), name];
                description = nil;
                notification = ChaxGrowlUserIdle;
                break;
            case IMPersonStatusAway:
                title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ went away"), name];
                description = statusMessage;
                notification = ChaxGrowlUserAway;
                break;
            case IMPersonStatusAvailable:
                if ([presentity previousStatus] == 1) {
                    title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ came online"), name];
                    description = nil;
                    notification = ChaxGrowlUserOnline;
                } else if ([presentity previousStatus] == 0) {
                    title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ changed status"), name];
                    description = statusMessage;
                    notification = ChaxGrowlUserStatusChanged;
                } else {
                    title = [NSString stringWithFormat:ChaxLocalizedString(@"%@ became available"), name];
                    description = statusMessage;
                    notification = ChaxGrowlUserAvailable;
                }
                break;
            default:
                return;
        }
        
        NSData *imageData = [[[presentity customPicture] image] TIFFRepresentation];
        
        if (imageData == nil) {
            imageData = [[[presentity genericPicture] image] TIFFRepresentation];
        }
        
        ChaxDebugLog(@"Posting Growl notification: %@ %@ %@", title, description, notification);
        
        [self postGrowlNotificationWithTitle:title description:description notificationName:notification iconData:imageData clickContext:[NSDictionary dictionaryWithObject:[presentity guid] forKey:@"IMHandle"]];
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
	NSArray *notifications = [NSArray arrayWithObjects:ChaxGrowlNewMessage, ChaxGrowlTextInvitation, ChaxGrowlUserOffline, ChaxGrowlUserOnline, ChaxGrowlUserIdle, ChaxGrowlUserAway, ChaxGrowlUserAvailable, ChaxGrowlUserStatusChanged, nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:notifications, GROWL_NOTIFICATIONS_ALL, notifications, GROWL_NOTIFICATIONS_DEFAULT, [[NSImage imageNamed:@"ChaxIcon"] TIFFRepresentation], GROWL_APP_ICON, nil];
}

- (NSString *)applicationNameForGrowl
{
	return @"Chax";
}

- (void)growlNotificationWasClicked:(NSDictionary *)clickContext
{
	if (clickContext) {
        Chat *chat = nil;
        
		[NSApp activateIgnoringOtherApps:YES];
		
		if ([clickContext objectForKey:@"Chat"]) {
            chat = [NSClassFromString(@"ChatWindowController") visibleChatWithID:[clickContext objectForKey:@"Chat"]];
        }
        
		if (chat == nil) {
			NSArray *accounts = [[IMAccountController sharedInstance] allConnectedAccounts];
			
			for (IMAccount *account in accounts) {
				IMHandle *handle = [account imHandleForGuid:[clickContext objectForKey:@"IMHandle"]];
				
				if (handle != nil) {
					chat = [NSClassFromString(@"ChatWindowController") existingChatWithIMHandle:handle];
                    
					if (!chat) {
						//There still may be a chat open with the given presentity, but existingChatWithPresentity isn't giving it up
						NSArray *chats = [NSClassFromString(@"Chat") chatList];
						
						for (Chat *nextChat in chats) {
							IMHandle *otherHandle = [nextChat otherIMHandle];
							if ([[otherHandle ID] isEqualToString:[otherHandle ID]] && [otherHandle service] == [otherHandle service]) {
                                chat = nextChat;
                                break;
							}
						}
						
						[NSClassFromString(@"ChatWindowController") displayChatForIMHandle:handle style:1];
                        ChaxDebugLog(@"Attempting to use displayChatForIMHandle: to display chat for %@", handle);
					}
                    
					break;
				}
			}
		}
        
        if (chat) {
            [[chat chatWindowController] chax_allowSelect];
            [NSClassFromString(@"ChatWindowController") displayChat:chat];
        } else {
            ChaxDebugLog(@"No chat found for Growl context: %@", clickContext);
        }
	}
}

@end
