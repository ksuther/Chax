/*
 * main.m
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

#import <Cocoa/Cocoa.h>

NSString *iChatBundleIdentifier = @"com.apple.iChat";

@interface ChaxHelperApp : NSObject
{}

@end

@implementation ChaxHelperApp

+ (void)applicationDidLaunch:(NSNotification *)note
{
    NSString *bundleIdentifier = [[note userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
    
    if ([bundleIdentifier isEqualToString:iChatBundleIdentifier]) {
        NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:@"tell application \"iChat\" to Load Chax"] autorelease];
        NSDictionary *errorInfo = nil;
        
        [script executeAndReturnError:&errorInfo];
        
        if (errorInfo != nil) {
            NSLog(@"Failed to load into iChat: %@", errorInfo);
        }
    }
}

@end

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:[ChaxHelperApp class] selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    
    [[NSApplication sharedApplication] run];
    
    [pool release];
}