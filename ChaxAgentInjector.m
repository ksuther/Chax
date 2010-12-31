/*
 * ChaxAgentInjector.m
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

#include <mach_inject_bundle/mach_inject_bundle.h>
#include <mach/mach_error.h>
#include <dlfcn.h>

NSString *iChatAgentBundleIdentifier = @"com.apple.iChatAgent";

void inject(pid_t pid, NSString *injectBundlePath);

int main(int argc, char **argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (argc == 3) {
        NSString *injectFrameworkPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSString *injectBundlePath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        NSArray *runningAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:iChatAgentBundleIdentifier];
        
        if ([runningAgents count] > 0) {
            pid_t pid = [[runningAgents lastObject] processIdentifier];
            
            //NSBundle is forbidden! the system will kill us if we try to load our framework using -[NSBundle bundleWithPath:]
            void *result = dlopen([[injectFrameworkPath stringByAppendingPathComponent:@"mach_inject_bundle"] fileSystemRepresentation], RTLD_NOW);
            
            if (result == 0x0) {
                NSLog(@"Failed to load mach_inject_bundle at %@", injectBundlePath);
            } else {
                inject(pid, injectBundlePath);
            }
        }
    }
    
    [pool release];
    
    return 0;
}

void inject(pid_t pid, NSString *injectBundlePath)
{
    if (injectBundlePath) {
        mach_error_t err = mach_inject_bundle_pid([injectBundlePath fileSystemRepresentation], pid);
        
        if (err != ERR_SUCCESS) {
            NSLog(@"Error while injecting into process %i: %s (system 0x%x, subsystem 0x%x, code 0x%x)", pid, mach_error_string(err), err_get_system(err), err_get_sub(err), err_get_code(err));
        }
    }
}