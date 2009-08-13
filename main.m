//
//  main.m
//  Chax
//
//  Created by Kent Sutherland on 6/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

/*
 * Copyright (C) 2006, 2007, 2008, 2009 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer. 
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution. 
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import <spawn.h>

static void displayErrorAndQuit(NSString *title, NSString *message)
{
	NSApplicationLoad();
	NSRunCriticalAlertPanel(title, message, @"Quit", nil, nil);
	exit(0);
}

static cpu_type_t preferredArchitecture()
{
#if defined(__ppc__)
    return CPU_TYPE_POWERPC;
#elif defined(__LP64__)
    return CPU_TYPE_X86_64;
#else
    return CPU_TYPE_X86;
#endif
}

static void myExecve(NSString *executable, NSArray *args, NSDictionary *environment)
{
    char **argv = (char **)calloc(sizeof(char *), [args count] + 1);
    char **env = (char **)calloc(sizeof(char *), [environment count] + 1);
	
    NSEnumerator *e = [args objectEnumerator];
    NSString *s;
    int i = 0;
    while ((s = [e nextObject]))
        argv[i++] = (char *) [s UTF8String];
	
    e = [environment keyEnumerator];
    i = 0;
    while ((s = [e nextObject]))
        env[i++] = (char *) [[NSString stringWithFormat:@"%@=%@", s, [environment objectForKey:s]] UTF8String];
	
    if (posix_spawnattr_init && posix_spawn && posix_spawnattr_setbinpref_np && posix_spawnattr_setflags) {
        posix_spawnattr_t attr;
        posix_spawnattr_init(&attr);
        cpu_type_t architecturePreference[] = { preferredArchitecture(), CPU_TYPE_X86 };
        posix_spawnattr_setbinpref_np(&attr, 2, architecturePreference, 0);
        short flags = POSIX_SPAWN_SETEXEC;
        posix_spawnattr_setflags(&attr, flags);
        posix_spawn(NULL, [executable fileSystemRepresentation], NULL, &attr, argv, env);
    } else
        execve([executable fileSystemRepresentation], argv, env);
}

static NSBundle *locateiChatBundle()
{
    NSArray *applicationDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSAllDomainsMask, YES);
    NSEnumerator *e = [applicationDirectories objectEnumerator];
    NSString *applicationDirectory;
    while ((applicationDirectory = [e nextObject])) {
        NSString *possibleiChatPath = [applicationDirectory stringByAppendingPathComponent:@"iChat.app"];
        NSBundle *possibleiChatBundle = [NSBundle bundleWithPath:possibleiChatPath];
        if ([[possibleiChatBundle bundleIdentifier] isEqualToString:@"com.apple.iChat"])
            return possibleiChatBundle;
    }
	
    CFURLRef iChatURL = nil;
    OSStatus err = LSFindApplicationForInfo(kLSUnknownCreator, CFSTR("com.apple.iChat"), nil, nil, &iChatURL);
    if (err != noErr)
        displayErrorAndQuit(@"Unable to locate iChat", @"Chax requires iChat to run.");
	
    NSBundle *iChatBundle = [NSBundle bundleWithPath:[(NSURL *)iChatURL path]];
    CFRelease(iChatURL);
    return iChatBundle;
}

static NSString *currentMacOSXVersion()
{
	SInt32 version;
	if (Gestalt(gestaltSystemVersion, &version) != noErr) {
		return @"10.4";
	}
	
	return [NSString stringWithFormat:@"%x.%x", (version & 0xFF00) >> 8, (version & 0x00F0) >> 4];
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSString *systemVersion = currentMacOSXVersion();
    NSBundle *iChatBundle = locateiChatBundle();
    NSString *executablePath = [iChatBundle executablePath];
    NSString *dylibPath = [[NSBundle mainBundle] pathForResource:@"ChaxLib" ofType:@"dylib"];
	
	if (![systemVersion isEqualToString:@"10.6"]) {
		displayErrorAndQuit(@"Incompatible system version",
                            @"This version of Chax requires Mac OS X 10.6 to run.");
	}
	
    if ([dylibPath rangeOfString:@":"].location != NSNotFound) {
        displayErrorAndQuit(@"Unable to launch iChat",
                            @"Chax is located at a path containing an unsupported character.  Please move Chax to a different location and try again.");
	}
	
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:executablePath];
	NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithObject:[[NSBundle mainBundle] bundlePath] forKey:@"ChaxAppPath"];
    [environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
	
	//Append the Chax dylib to the existing DYLIB_INSERT_LIBRARIES key if it exists
	NSString *insertLibraries = [environment objectForKey:@"DYLD_INSERT_LIBRARIES"];
	
	if (insertLibraries) {
        [environment setObject:insertLibraries forKey:@"ChaxOriginalInsertLibraries"];
		[environment setObject:[insertLibraries stringByAppendingFormat:@":%@", dylibPath] forKey:@"DYLD_INSERT_LIBRARIES"];
	} else {
		[environment setObject:dylibPath forKey:@"DYLD_INSERT_LIBRARIES"];
	}
	
    while (*++argv) {
        [arguments addObject:[NSString stringWithUTF8String:*argv]];
	}
	
    myExecve(executablePath, arguments, environment);
	
    char *error = strerror(errno);
    NSString *errorMessage = [NSString stringWithFormat:@"Launching iChat at %@ failed with the error '%s' (%d)", [iChatBundle bundlePath], error, errno];
    displayErrorAndQuit(@"Unable to launch iChat", errorMessage);
	
    [pool release];
    return 0;
}
