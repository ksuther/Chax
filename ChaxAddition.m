/*
 * ChaxAddition.m
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

#include <Carbon/Carbon.h>

#pragma GCC visibility push(default)

#ifdef __cplusplus
extern "C" {
#endif

OSErr ChaxLoad(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon);
OSErr ChxLLoad(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon);

#ifdef __cplusplus
}
#endif

#pragma GCC visibility pop

OSErr ChaxLoad(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	//Only load into iChat
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.iChat"]) {
        NSBundle *additionBundle = [NSBundle bundleWithIdentifier:@"com.ksuther.chax.addition"];
        NSString *chaxLibPath = [additionBundle pathForResource:@"ChaxLib" ofType:@"bundle"];
        NSBundle *chaxBundle = [NSBundle bundleWithPath:chaxLibPath];
        
        if (![chaxBundle isLoaded]) {
            [chaxBundle load];
        }
    }
	
	[pool release];
    
	return noErr;
}

OSErr ChxLLoad(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //Only load into iChatAgent
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.iChatAgent"]) {
        NSBundle *additionBundle = [NSBundle bundleWithIdentifier:@"com.ksuther.chax.addition"];
        NSString *chaxAgentLibPath = [additionBundle pathForResource:@"ChaxAgentLib" ofType:@"bundle"];
        NSBundle *chaxAgentBundle = [NSBundle bundleWithPath:chaxAgentLibPath];
        
        if (![chaxAgentBundle isLoaded]) {
            [chaxAgentBundle load];
        }
    }
    
	[pool release];
    
	return noErr;
}