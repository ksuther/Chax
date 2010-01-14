/*
 * ChaxAgentPermissionRepair.m
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

#import "ChaxAgentPermissionRepair.h"
#import "Chax.h"
#import <sys/stat.h>
#import <Security/Security.h>

BOOL ChaxAgentInjectorPerformInjection()
{
    NSBundle *chaxLibBundle = [NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier];
    NSString *injectorPath = [chaxLibBundle pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    NSArray *arguments = [NSArray arrayWithObjects:[[chaxLibBundle privateFrameworksPath] stringByAppendingPathComponent:@"mach_inject_bundle.framework"], [chaxLibBundle pathForResource:@"ChaxAgentLib" ofType:@"bundle"], nil];
    
    [NSTask launchedTaskWithLaunchPath:injectorPath arguments:arguments];
}

BOOL ChaxAgentInjectorNeedsPermissionRepair()
{
    struct stat statResult;
    NSString *injectorPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:injectorPath error:nil];
    
    //Is ChaxAgentInjector not setgid and in the group procmod?
    return ![[attributes fileGroupOwnerAccountName] isEqualToString:@"procmod"] || ([attributes filePosixPermissions] & 02000 == 0);
}

BOOL ChaxAgentInjectorRepairPermissions()
{
    NSString *targetPath = [[NSBundle bundleWithIdentifier:ChaxLibBundleIdentifier] pathForAuxiliaryExecutable:@"ChaxAgentInjector"];
    OSStatus err = noErr;
    
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
                
                args[0] = "procmod";
                args[1] = (char *)[targetPath fileSystemRepresentation];
                args[2] = NULL;
                
                err = AuthorizationExecuteWithPrivileges(authorizationRef, "/usr/bin/chgrp", 0, args, NULL);
                
                if (err == noErr) {
                    err = AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
                }
            }
        }
        
        if (err != noErr) {
            NSRunAlertPanel(ChaxLocalizedString(@"Permission repair error"), ChaxLocalizedString(@"There was an error repairing permissions. Please try again or reinstall Chax if the problem persists. (Error %d)"), @"OK", nil, nil, err);
        }
    } else {
        NSLog(@"Unable to locate ChaxAgentInjector.");
        
        err = 1;
    }
    
    return err == noErr;
}
