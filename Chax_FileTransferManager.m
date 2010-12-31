/*
 * Chax_FileTransferManager.m
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

#import "Chax_FileTransferManager.h"
#import "IMFoundation.h"
#import "IMCore.h"
#import "iChat5.h"

@implementation Chax_FileTransferManager

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chax_fileTransferUpdatedNotification:) name:@"IMFileTransferUpdatedNotification" object:nil];
}

+ (void)chax_fileTransferUpdatedNotification:(NSNotification *)note
{
    IMFileTransfer *transfer = [note object];
    
    if ([Chax boolForKey:@"AutoclearFileTransfers"]) {
        if ([transfer transferState] == 4 && [transfer error] == 0) {
            [self cancelPreviousPerformRequestsWithTarget:self selector:@selector(chax_removeSuccessfulTransfers) object:nil];
            [self performSelector:@selector(chax_removeSuccessfulTransfers) withObject:nil afterDelay:2.0];
        }
    }
    
    if ([transfer transferState] == 5 && [[transfer localPath] rangeOfString:TemporaryImagePath()].location == NSNotFound) {
        //Let the activity window know that a file transfer was completed
        BOOL isIncoming = [transfer isIncoming];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[transfer otherPerson], @"name",
                                                                            [NSNumber numberWithInt:isIncoming ? 101 : 102], @"type",
                                                                            [transfer localPath], @"path", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ChaxFileTransferCompleted" object:nil userInfo:userInfo];
    }
}

+ (void)chax_removeSuccessfulTransfers
{
    FileTransferManager *transferManager = [NSClassFromString(@"FileTransferManager") sharedInstance];
    
    NSSet *transfers = [transferManager _transfersMatchingCondition:1 wantsGUIDs:NO];
    ViewTable *viewTable = [transferManager valueForKey:@"_table"];
    NSArray *subviews = [viewTable subviews];
    
    for (NSView *nextView in subviews) {
        if ([nextView isKindOfClass:NSClassFromString(@"FileTransferView")]) {
            [(FileTransferView *)nextView _deselect];
        }
    }
    
    for (NSView *nextView in subviews) {
        if ([nextView isKindOfClass:NSClassFromString(@"FileTransferView")]) {
            FileTransferView *fileTransferView = (FileTransferView *)nextView;
            FileTransfer *fileTransfer = [fileTransferView fileTransfer];
            
            if ([fileTransfer error] == 0 && [transfers containsObject:fileTransfer]) {
                [fileTransferView _setSelected];
            }
        }
    }
    
    [viewTable selectionDidChange];
    
    [transferManager deleteSelectedRowsInViewTable:nil];
}

- (void)chax_swizzle_windowDidLoad
{
    [self chax_swizzle_windowDidLoad];
    
    [[self class] chax_removeSuccessfulTransfers];
}

@end
