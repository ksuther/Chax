/*
 * DonateWindowController.m
 *
 * Copyright (c) 2007-2010 Kent Sutherland
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

#import "DonateWindowController.h"

@implementation DonateWindowController

@synthesize donateString = _donateString;

- (id)initWithMessage:(NSString *)string
{
	if ( (self = [super initWithWindowNibName:@"Donate" owner:self]) ) {
		self.donateString = string;
	}
	return self;
}

- (void)dealloc
{
	[_donateString release];
	[super dealloc];
}

- (void)windowDidLoad
{
	[_donateText setStringValue:self.donateString];
	
	[[self window] center];
}

- (IBAction)buttonAction:(id)sender
{
	if ([sender tag] == 1) {
		[[NSWorkspace sharedWorkspace] openURL:DONATE_URL];
	}
	
	[self close];
	[self autorelease];
}

@end
