/*
 * Chax_StatusController.m
 *
 * Copyright (c) 2011 Kent Sutherland
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

#import "Chax_StatusController.h"
#import "UnifiedPeopleListController_Provider.h"

@implementation Chax_StatusController

- (void)chax_swizzle_myStatusControl:(id)fp8 changedStatus:(int)fp12 message:(id)fp16
{
    if (fp12 == IMPersonStatusOffline && self == [[NSClassFromString(@"UnifiedPeopleListController") sharedController] valueForKey:@"_myStatusController"]) {
        //if the user selects offline from the status popup in the unified contact list, sign off all accounts
        //this is here because logServiceInOrOut: isn't called when offline is selected here
        [[IMDaemonController sharedController] logoutAllAccounts];
    }
    
    [self chax_swizzle_myStatusControl:fp8 changedStatus:fp12 message:fp16];
}

@end
