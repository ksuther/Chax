/*
 * Chax_AIMServiceSession.m
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

#import "Chax_AIMServiceSession.h"
#import "BundleUtilities.h"
#import "IMFoundation.h"
#import "Chax_SuperToAIMParserContext.h"

@implementation Chax_AIMServiceSession

+ (void)load
{
    NSLog(@"ChaxAgentLib loaded.");
    
    if (NSClassFromString(@"AIMServiceSession") != nil) {
        Class swizzleTargetClass = NSClassFromString(@"AIMServiceSession");
        
        [BundleUtilities extendClass:swizzleTargetClass withMethodsFromClass:self];
        
        MethodSwizzle(swizzleTargetClass, @selector(_sendMessage:toBuddy:secure:), @selector(chax_swizzle__sendMessage:toBuddy:secure:));
    } else {
        NSLog(@"Error swizzling AIMServiceSession");
    }
    
    if (NSClassFromString(@"SuperToAIMParserContext") != nil) {
        Class swizzleTargetClass = NSClassFromString(@"SuperToAIMParserContext");
        
        [BundleUtilities extendClass:swizzleTargetClass withMethodsFromClass:NSClassFromString(@"Chax_SuperToAIMParserContext")];
        
        MethodSwizzle(swizzleTargetClass, @selector(outAIML), @selector(chax_swizzle_outAIML));
        MethodSwizzle(swizzleTargetClass, @selector(initWithAttributedString:markupMode:), @selector(chax_swizzle_initWithAttributedString:markupMode:));
    } else {
        NSLog(@"Error swizzling SuperToAIMParserContext");
    }
}

- (int)chax_swizzle__sendMessage:(id)arg1 toBuddy:(id)arg2 secure:(BOOL)arg3
{
    CFPreferencesSynchronize(CFSTR("com.ksuther.chax"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    
    if ([arg2 isICQ] && CFPreferencesGetAppBooleanValue((CFStringRef)@"ICQPlainTextEnabled", (CFStringRef)@"com.ksuther.chax", nil)) {
        chax_sendNextPlainText = YES;
    }
    
    return [self chax_swizzle__sendMessage:arg1 toBuddy:arg2 secure:arg3];
}

@end
