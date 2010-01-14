/*
 * Chax_Account.h
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

#import "Chax_Account.h"
#import "UnifiedPeopleListController_Provider.h"
#import "StatusChangeController.h"

@implementation Chax_Account

- (void)chax_swizzle_loginStatusChanged:(unsigned int)fp8 message:(id)fp12 reason:(unsigned int)fp16 properties:(id)fp20
{
	[self chax_swizzle_loginStatusChanged:fp8 message:fp12 reason:fp16 properties:fp20];
	
	if (fp8 == 0) {
		[[NSClassFromString(@"UnifiedPeopleListController") sharedController] reloadContacts];
	}
	
	//[[UnifiedPeopleListController sharedController] rebuildAddBuddyMenu];
}

- (void)chax_swizzle_invitedToChat:(id)fp8 isChatRoom:(BOOL)fp12 invitation:(id)fp16
{
	if ([[(NSString *)[fp16 sender] lowercaseString] isEqualToString:@"aolsystemmsg"] && [Chax boolForKey:@"BlockAOLSystemMessage"]) {
		return;
	}
	
	[self chax_swizzle_invitedToChat:fp8 isChatRoom:fp12 invitation:fp16];
	
	if (![NSApp isActive] || [Chax boolForKey:@"AlwaysShowGrowlNotifications"]) {
		InstantMessage *message = [self _createInstantMessage:fp16 chatID:fp8];
		Presentity *presentity = [message sender];
		
		if ([[[message text] string] length] > 0) {
            NSData *imageData = [[[presentity customPicture] image] TIFFRepresentation];
            
            if (imageData == nil) {
                imageData = [[[presentity genericPicture] image] TIFFRepresentation];
            }
            
			[[StatusChangeController sharedController] postGrowlNotificationWithTitle:[NSString stringWithFormat:ChaxLocalizedString(@"%@ says"), [presentity name]]
                                                                          description:[[message text] string]
                                                                     notificationName:ChaxGrowlTextInvitation
                                                                             iconData:imageData
                                                                         clickContext:[NSDictionary dictionaryWithObject:fp8 forKey:@"Chat"]];
		}
	}
	
	/*if ([Chax boolForKey:@"StopScreensaverOnNewIM"]) {
		[Chax undimScreenAndStopScreenSaver];
	}*/
}

- (void)chax_swizzle_handleChat:(id)fp8 messageReceived:(id)fp12
{
	[self chax_swizzle_handleChat:fp8 messageReceived:fp12];
    
	if (![NSApp isActive] || [Chax boolForKey:@"AlwaysShowGrowlNotifications"]) {
		InstantMessage *message = [self _createInstantMessage:fp12 chatID:fp8];
        Presentity *presentity = [[[NSClassFromString(@"Fezz") sharedInstance] _imHandlesWithIDs:[NSArray arrayWithObject:[fp12 sender]] forAccount:self] lastObject];
		
		//Post notification only if the message was received from another user, and if there was an associated message
		if ([fp12 flags] == 1 && [[[message text] string] length] > 0) {
            NSData *imageData = [[[presentity customPicture] image] TIFFRepresentation];
            
            if (imageData == nil) {
                imageData = [[[presentity genericPicture] image] TIFFRepresentation];
            }
            
			[[StatusChangeController sharedController] postGrowlNotificationWithTitle:[NSString stringWithFormat:ChaxLocalizedString(@"%@ says"), [presentity name]]
                                                                          description:[[message text] string]
                                                                     notificationName:ChaxGrowlNewMessage
                                                                             iconData:imageData
                                                                         clickContext:[NSDictionary dictionaryWithObject:fp8 forKey:@"Chat"]];
		}
        
	}
	
	/*if ([fp12 flags] == 1) {
		if ([Chax boolForKey:@"StopScreensaverOnIM"]) {
			[Chax undimScreenAndStopScreenSaver];
		}
	}*/
}

@end
