/*
 * Chax_ActionsControllerHandler.m
 *
 * Copyright (c) 2007-2011 Kent Sutherland
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

#import "Chax_ActionsControllerHandler.h"
#import "StatusChangeController.h"

@implementation Chax_ActionsControllerHandler

- (id)chax_swizzle_performActionsForEvent:(int)fp8 withIMHandle:(Presentity *)fp12 withObject:(InstantMessage *)fp16 withChat:(IMChat *)fp20 silent:(BOOL)fp24
{
    //5 is an incoming message, 10 is an incoming invitation
    if (fp8 == 5 || fp8 == 10) {
        if ((![NSApp isActive] || [Chax boolForKey:@"AlwaysShowGrowlNotifications"]) && ![fp16 isFromMe] && [(NSAttributedString *)[fp16 text] length] > 0) {
            NSData *imageData = [[[fp12 customPicture] image] TIFFRepresentation];
            
            if (imageData == nil) {
                imageData = [[[fp12 picture] image] TIFFRepresentation];
            }
            
			[[StatusChangeController sharedController] postGrowlNotificationWithTitle:[NSString stringWithFormat:ChaxLocalizedString(@"%@ says"), [fp12 name]]
                                                                          description:[[fp16 text] string]
                                                                     notificationName:(fp8 == 10) ? ChaxGrowlTextInvitation : ChaxGrowlNewMessage
                                                                             iconData:imageData
                                                                         clickContext:[NSDictionary dictionaryWithObject:[fp20 chatIdentifier] forKey:@"Chat"]];
        }
    }
    
    if (fp8 == 10 && [fp20 joinState] == 0 && [Chax boolForKey:@"SkipNewMessageNotification"] && [fp20 chatStyle] == '-') {
        ChatController *controller = [NSClassFromString(@"ChatWindowController") chatControllerForChat:fp20];
        
        [[controller notifier] performSelector:@selector(acceptNotification) withObject:nil afterDelay:0.0];
    }
    
    return [self chax_swizzle_performActionsForEvent:fp8 withIMHandle:fp12 withObject:fp16 withChat:fp20 silent:fp24];
}

@end
