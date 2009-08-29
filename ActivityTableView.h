//
//  ActivityTableView.h
//  Chax
//
//  Created by Kent Sutherland on 6/22/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ActivityTableView : NSTableView {

}

@end

@interface NSObject (ActivityTableViewDelegate)
- (void)deleteKeyPressedInTableView:(NSTableView *)tableView;
@end
