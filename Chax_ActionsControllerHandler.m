/*
 * Chax_ActionsControllerHandler.m
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

#import "Chax_ActionsControllerHandler.h"
#import "iChat5.h"

@implementation Chax_ActionsControllerHandler

- (id)chax_swizzle_performActionsForEvent:(int)fp8 withIMHandle:(id)fp12 withObject:(id)fp16 withChat:(id)fp20 silent:(BOOL)fp24
{
    //joinState of 0 means that the notifier window is still up
    //isChat being true means it is a group chat, so don't auto-accept those (auto-accepting group chats also crashes)
    if (fp20 && [fp20 isKindOfClass:NSClassFromString(@"ActiveChat")] && [fp20 joinState] == 0 && ![fp20 isChat] && [Chax boolForKey:@"SkipNewMessageNotification"]) {
		[[[fp20 chatController] notifier] performSelector:@selector(acceptNotification) withObject:nil afterDelay:0.0];
	}
    
    return [self chax_swizzle_performActionsForEvent:fp8 withIMHandle:fp12 withObject:fp16 withChat:fp20 silent:fp24];
}

@end
