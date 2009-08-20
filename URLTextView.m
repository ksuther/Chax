//
//  URLTextView.m
//  AppShopper
//
//  Created by Kent Sutherland on 7/13/09.
//  Copyright 2009 Kent Sutherland. All rights reserved.
//

#import "URLTextView.h"

@implementation URLTextView

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	return NSMakeRange(0, 0);
}

@end
