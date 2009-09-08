/*
 * Chax_IMFileTransferCenter.m
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
 
#import "Chax_IMFileTransferCenter.h"
#import "IMFoundation.h"
#import "IMCore.h"
#import "iChat5.h"

@implementation Chax_IMFileTransferCenter

- (void)chax_swizzle__addPendingTransfer:(id)fp8
{
    [self chax_swizzle__addPendingTransfer:fp8];
    
    IMFileTransfer *transfer = [self transferForGUID:fp8];
    
    if ([Chax boolForKey:@"AutoAcceptFiles"] && [transfer isIncoming]) {
        NSArray *autoAcceptContacts = [[Chax objectForKey:@"AutoAccept.Files"] objectForKey:[transfer accountID]];
        
        if ([Chax integerForKey:@"AutoAcceptSelect.Files"] == 0 || [autoAcceptContacts containsObject:@"Chax_AcceptAnyone"] || [autoAcceptContacts containsObject:[[transfer otherPerson] lowercaseString]]) {
            [self performSelector:@selector(chax_autoAcceptTransfer:) withObject:transfer afterDelay:0.0];
        }
    }
}

- (void)chax_autoAcceptTransfer:(IMFileTransfer *)transfer
{
    [NSClassFromString(@"FileTransferManager") fileTransfer:transfer saveTo:nil attachedToWindow:nil];
}

@end
