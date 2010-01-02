/*
 * LogViewerQuickLookController.m
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

#import "LogViewerQuickLookController.h"
#import "LogViewerPreviewItem.h"
#import "iChat5.h"

@implementation LogViewerQuickLookController

@synthesize imagePath = _imagePath;

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    return (selector != @selector(quickLookImage:));
}

- (void)dealloc
{
    [_imagePath release];
    
    [super dealloc];
}

- (void)quickLookImage:(NSString *)imageName
{
    NSString *imagePath = [TemporaryImagePath() stringByAppendingPathComponent:imageName];
    QLPreviewPanel *panel = [QLPreviewPanel sharedPreviewPanel];
    
    [self setImagePath:imagePath];
    
    [panel makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark QLPreviewPanel Data Source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [LogViewerPreviewItem previewItemWithURL:[NSURL fileURLWithPath:[self imagePath]]];
}

@end
