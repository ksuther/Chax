/*
 * Chax_ChatWindowController.m
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

#import "Chax_ChatWindowController.h"
#import "CameraSnapshotController.h"

Chat *_lastChat = nil;

@implementation Chax_ChatWindowController

- (void)chax_swizzle_addChatInvite:(id)fp8 withNotifierWindow:(id)fp12
{
	_lastChat = fp8;
    
	[self chax_swizzle_addChatInvite:fp8 withNotifierWindow:fp12];
    
    if ([fp8 chatStyle] == '-' && [Chax boolForKey:@"SkipNewMessageNotification"]) {
        [fp12 setAlphaValue:0.0];
    }
}

- (void)chax_swizzle_windowDidLoad
{
	[self chax_swizzle_windowDidLoad];
	
	if ([Chax boolForKey:@"HideChatsWhenInactive"]) {
		[[self window] setHidesOnDeactivate:YES];
	}
}

- (void)chax_swizzle__chatAddedToList:(id)sender
{
    [self chax_swizzle__chatAddedToList:sender];
    
    if ([Chax boolForKey:@"HideChatsWhenInactive"]) {
		[[self window] setHidesOnDeactivate:YES];
	}
}

-(void)chax_swizzle__startNotifierAnimationTimer
{
    [self chax_swizzle__startNotifierAnimationTimer];
    
    if ([Chax boolForKey:@"SkipNewMessageNotification"]) {
        [self cancelActiveNotifierAnimations];
    }
}

- (void)chax_swizzle_displayChat:(id)fp8
{
	if ([Chax boolForKey:@"SkipNewMessageNotification"] && _lastChat && _lastChat == fp8) {
        if ([fp8 chatStyle] == '-') {
            [self performSelector:@selector(chax_allowSelect) withObject:nil afterDelay:0.0];
        } else {
            //This is a group chat, display it immediately since it came through a notifier
            [self performSelector:@selector(chax_allowSelect) withObject:nil afterDelay:0.0];
            
            [self chax_swizzle_displayChat:fp8];
        }
	} else {
		[self chax_swizzle_displayChat:fp8];
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
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.6] forKey:NSImageCompressionFactor];
    NSString *imagePath = [[NSFileManager defaultManager] _randomTemporaryPathWithFileName:@"Snapshot.jpeg"];
    
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:imagePath atomically:NO];
    
    ChatController *chatController = [self currentChatController];
    
    [[chatController window] makeFirstResponder:[chatController inputLine]];
	[[chatController fieldEditor] insertFileURL:[NSURL fileURLWithPath:imagePath]];
	
	[cameraSnapshotController release];
}

@end
