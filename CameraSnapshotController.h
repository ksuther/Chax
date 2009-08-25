//
//  CameraSnapshotController.h
//  Chax
//
//  Created by Kent Sutherland on 2/4/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CameraPreferencesView;

@interface CameraSnapshotController : NSWindowController {
	IBOutlet CameraPreferencesView *_cameraView;
	IBOutlet NSButton *_flipButton;
	IBOutlet NSButton *_sendButton;
	
	id _delegate;
}

@property(assign, nonatomic) id delegate;

- (IBAction)send:(id)sender;

@end

@interface NSObject (CameraSnapshotControllerDelegate)
- (void)cameraSnapshotControllerDidCancel:(CameraSnapshotController *)cameraSnapshotController;
- (void)cameraSnapshotController:(CameraSnapshotController *)cameraSnapshotController didTakeSnapshot:(NSImage *)image;
@end
