//
//  Chax_IMChatRegistry.m
//  Chax
//
//  Created by Kent Sutherland on 9/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Chax_IMChatRegistry.h"
#import "StatusChangeController.h"

@implementation Chax_IMChatRegistry

- (void)chax_swizzle_account:(id)arg1 chat:(id)arg2 style:(unsigned char)arg3 chatProperties:(id)arg4 invitationReceived:(id)arg5
{
    if ([[(NSString *)[arg5 handle] lowercaseString] isEqualToString:@"aolsystemmsg"] && [Chax boolForKey:@"BlockAOLSystemMessage"]) {
		return;
	}
    
    [self chax_swizzle_account:arg1 chat:arg2 style:arg3 chatProperties:arg4 invitationReceived:arg5];
}

- (void)chax_swizzle_account:(id)arg1 chat:(id)arg2 style:(unsigned char)arg3 chatProperties:(id)arg4 messageReceived:(id)arg5
{
    [self chax_swizzle_account:arg1 chat:arg2 style:arg3 chatProperties:arg4 messageReceived:arg5];
    
    if (![NSApp isActive] || [Chax boolForKey:@"AlwaysShowGrowlNotifications"]) {
		//Post notification only if the message was received from another user, and if there was an associated message
		if (![arg5 isFromMe] && [[(FZMessage *)arg5 body] length] > 0) {
            IMChat *chat = [[NSClassFromString(@"IMChatRegistry") sharedInstance] existingChatWithChatIdentifier:arg2];
            Presentity *presentity = [[chat account] existingIMHandleWithID:[arg5 handle]];
            NSData *imageData = [[[presentity customPicture] image] TIFFRepresentation];
            
            if (imageData == nil) {
                imageData = [[[presentity picture] image] TIFFRepresentation];
            }
            
			[[StatusChangeController sharedController] postGrowlNotificationWithTitle:[NSString stringWithFormat:ChaxLocalizedString(@"%@ says"), [presentity name]]
                                                                          description:[[(FZMessage *)arg5 body] string]
                                                                     notificationName:ChaxGrowlNewMessage
                                                                             iconData:imageData
                                                                         clickContext:[NSDictionary dictionaryWithObject:[chat chatIdentifier] forKey:@"Chat"]];
		}
        
	}
    
    /*if ([fp12 flags] == 1) {
        if ([Chax boolForKey:@"StopScreensaverOnIM"]) {
            [Chax undimScreenAndStopScreenSaver];
        }
    }*/
}

@end
