//
//  Chax_FileTransferManager.m
//  Chax
//
//  Created by Kent Sutherland on 8/25/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

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
    if ([Chax boolForKey:@"AutoclearFileTransfers"]) {
        IMFileTransfer *transfer = [note object];
        
        if ([transfer transferState] == 4 && [transfer error] == 0) {
            [self cancelPreviousPerformRequestsWithTarget:self selector:@selector(chax_removeSuccessfulTransfers) object:nil];
            [self performSelector:@selector(chax_removeSuccessfulTransfers) withObject:nil afterDelay:2.0];
        }
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
