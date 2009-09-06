/*
 * Chax_ChatWindowController.m
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

#import "Chax_ChatWindowController.h"
#import "CameraSnapshotController.h"
#import "iChat5.h"

Chat *_lastChat = nil;

@implementation Chax_ChatWindowController

- (void)chax_swizzle_addChatInvite:(id)fp8 withNotifierWindow:(id)fp12
{
	_lastChat = fp8;
    
	[self chax_swizzle_addChatInvite:fp8 withNotifierWindow:fp12];
}

- (void)chax_swizzle_displayChat:(id)fp8
{
	if ([Chax boolForKey:@"SkipNewMessageNotification"] && _lastChat && _lastChat == fp8) {
		[self performSelector:@selector(chax_allowSelect) withObject:nil afterDelay:0.0];
	} else {
		[self chax_swizzle_displayChat:fp8];
	}
}

-(void)chax_swizzle__startNotifierAnimationTimer
{
    [self chax_swizzle__startNotifierAnimationTimer];
    
    if ([Chax boolForKey:@"SkipNewMessageNotification"]) {
        [self cancelActiveNotifierAnimations];
    }
}

- (void)chax_allowSelect
{
	_lastChat = nil;
}

- (void)chax_sendCameraSnapshot:(id)sender
{
	CameraSnapshotController *controller = [[CameraSnapshotController alloc] init];
	
	controller.delegate = self;
	[controller showWindow:nil];
}

#pragma mark -
#pragma mark CameraSnapshotController Delegate

- (void)cameraSnapshotControllerDidCancel:(CameraSnapshotController *)cameraSnapshotController
{
	[cameraSnapshotController release];
}

- (void)cameraSnapshotController:(CameraSnapshotController *)cameraSnapshotController didTakeSnapshot:(NSImage *)image
{
    NSString *tempImagePath = TemporaryImagePath();
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.6] forKey:NSImageCompressionFactor];
    NSString *imagePath = [tempImagePath stringByAppendingPathComponent:[NSString stringWithFormat:@"iChat Image(%lu).jpeg", (unsigned long)SecureRandomUInt()]];
    
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:imagePath atomically:NO];
    
	[[[self currentChatController] fieldEditor] insertAttachedFile:imagePath];
	
	[cameraSnapshotController release];
}

@end
