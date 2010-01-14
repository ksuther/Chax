/*
 * ChaxDefaults.m
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

#import "ChaxDefaults.h"

@implementation ChaxDefaults

//This can be used to set first-run defaults if necessary
- (id)init
{
    if ([super init]) {
        if ([[NSUserDefaults standardUserDefaults] persistentDomainForName:ChaxBundleIdentifier] == nil) {
            NSMutableDictionary *defaultSettings = [NSMutableDictionary dictionary];
            
            [defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:@"PreferAllContacts"];
            
            [[NSUserDefaults standardUserDefaults] setPersistentDomain:defaultSettings forName:ChaxBundleIdentifier];
        }
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	
	NSMutableDictionary *dictionary = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:ChaxBundleIdentifier] mutableCopy];
	[dictionary setValue:value forKey:key];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:dictionary forName:ChaxBundleIdentifier];
	[dictionary release];
	
	[self didChangeValueForKey:key];
}

- (id)valueForKey:(NSString *)key
{
	return [[[NSUserDefaults standardUserDefaults] persistentDomainForName:ChaxBundleIdentifier] valueForKey:key];
}

@end
