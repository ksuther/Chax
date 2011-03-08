/*
 * ChaxAgentPermissionRepair.m
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

#import "ChaxAgentPermissionRepair.h"
#import "Chax.h"
#import <sys/stat.h>
#import <Security/Security.h>
#import <sys/sysctl.h>

BOOL ChaxAgentInjectorCheckAndInject()
{
    if (ChaxAgentInjectorNeedsPermissionRepair()) {
        if (NSRunAlertPanel(ChaxLocalizedString(@"Administrator password required"),
                            ChaxLocalizedString(@"Sending plain text to ICQ users requires your admin password to function properly. Please enter your admin password to enable this feature."),
                            ChaxLocalizedString(@"OK"),
                            ChaxLocalizedString(@"Cancel"), nil) == NSAlertDefaultReturn) {
            ChaxAgentInjectorRepairPermissions();
        }
    }
    
    return ChaxAgentInjectorPerformInjection();
}

BOOL ChaxAgentInjectorPerformInjection()
{
    NSBundle *chaxLibBundle = [NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier];
    NSString *injectorPath = [chaxLibBundle pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    NSArray *runningAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:iChatAgentBundleIdentifier];
    
    ChaxDebugLog(@"Attempting to perform injection into iChatAgent. %d running agents found.", [runningAgents count]);
    
    if ([runningAgents count] > 0) {
        //NSRunningApplication executableArchitecture isn't working here for some reason
        //Using solution from http://stackoverflow.com/questions/1350181/determine-a-processs-architecture instead (same as in top source)
        
        //Check the architecture of iChatAgent so we run the injector with the same architecture, otherwise mach_inject will fail
        pid_t pid = [[runningAgents lastObject] processIdentifier];
        cpu_type_t cpuType;
        size_t cpuTypeSize;
        int mib[CTL_MAXNAME];
        size_t mibLen = CTL_MAXNAME;
        int err;
        
        err = sysctlnametomib("sysctl.proc_cputype", mib, &mibLen);
        
        if (err == -1) {
            err = errno;
        }
        
        if (err == 0) {
            assert(mibLen < CTL_MAXNAME);
            mib[mibLen] = pid;
            mibLen += 1;
            
            cpuTypeSize = sizeof(cpuType);
            err = sysctl(mib, mibLen, &cpuType, &cpuTypeSize, 0, 0);
            if (err == -1) {
                err = errno;
            }
        }
        
        NSString *architectureString = (cpuType & CPU_ARCH_ABI64) ? @"x86_64" : @"i386";
        NSArray *arguments = [NSArray arrayWithObjects:@"-arch", architectureString, injectorPath, [[chaxLibBundle privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"], [chaxLibBundle pathForResource:@"ChaxAgentLib" ofType:@"bundle"], nil];
        
        [NSTask launchedTaskWithLaunchPath:@"/usr/bin/arch" arguments:arguments];
        
        ChaxDebugLog(@"Launched with arguments: %@", arguments);
    }
    
    return YES;
}

BOOL ChaxAgentInjectorNeedsPermissionRepair()
{
    NSString *injectorPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:injectorPath error:nil];
    
    //Is ChaxAgentInjector not setgid and in the group procmod?
    return ![[attributes fileGroupOwnerAccountName] isEqualToString:@"procmod"] || (([attributes filePosixPermissions] & 02000) == 0);
}

BOOL ChaxAgentInjectorRepairPermissions()
{
    NSString *targetPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    OSStatus err = noErr;
    
    ChaxDebugLog(@"Attempting ChaxAgentInjector permission repair.");
    
    if (targetPath) {
        AuthorizationRef authorizationRef;
        AuthorizationItem items[1];
        AuthorizationRights rights;
        
        err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
        
        if (err == noErr) {
            items[0].name = kAuthorizationRightExecute;
            items[0].value = NULL;
            items[0].valueLength = 0;
            items[0].flags = 0;
            
            rights.count = 1;
            rights.items = items;
            
            err = AuthorizationCopyRights(authorizationRef, &rights, kAuthorizationEmptyEnvironment, kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights, NULL);
            
            if (err == noErr) {
                char *args[3];
                
                args[0] = "g+s";
                args[1] = (char *)[targetPath fileSystemRepresentation];
                args[2] = NULL;
                
                err = AuthorizationExecuteWithPrivileges(authorizationRef, "/bin/chmod", 0, args, NULL);
                ChaxDebugLog(@"Ran chmod (%d).", err);
                
                args[0] = "procmod";
                args[1] = (char *)[targetPath fileSystemRepresentation];
                args[2] = NULL;
                
                err = AuthorizationExecuteWithPrivileges(authorizationRef, "/usr/bin/chgrp", 0, args, NULL);
                ChaxDebugLog(@"Ran chgrp (%d).", err);
                
                if (err == noErr) {
                    err = AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
                }
            }
        }
        
        if (err != noErr) {
            NSRunAlertPanel(ChaxLocalizedString(@"Administrator password error"), ChaxLocalizedString(@"There was an error enabling plain text support for ICQ users. Please try again or reinstall Chax if the problem persists. (Error %d)"), @"OK", nil, nil, err);
        }
    } else {
        NSLog(@"Unable to locate ChaxAgentInjector.");
        
        err = 1;
    }
    
    return err == noErr;
}
