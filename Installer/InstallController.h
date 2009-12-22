//
//  InstallController.h
//  Chax
//
//  Created by Kent Sutherland on 12/19/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InstallController : NSObject {
    IBOutlet NSWindow *_window;
    IBOutlet NSButton *_installButton;
    IBOutlet NSButton *_removeButton;
    
    IBOutlet NSTextField *_installTitle;
    IBOutlet NSTextField *_installText;
}

- (void)updateInstallInfo;

- (void)displaySheetTitled:(NSString *)title message:(NSString *)message defaultButton:(NSString *)defaultButton secondaryButton:(NSString *)secondaryButton callback:(SEL)callback;
- (void)displayError:(NSError *)error;
- (void)setLaunchAtLogin:(BOOL)enabled;

- (NSString *)chaxAdditionPath;
- (NSString *)installedHelperAppPath;

- (IBAction)install:(id)sender;
- (IBAction)remove:(id)sender;

@end
