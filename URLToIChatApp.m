/*
 * URLToIChatApp.m
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

NSURL *URLToIChatApp();

#pragma mark -
#pragma mark URLToIChatApp Override

#define DYLD_INTERPOSE(_replacment,_replacee) \
__attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
__attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee };

NSURL * _ChaxURLToIChatApp()
{
    //Remove ChaxAgentLib from DYLD_INSERT_LIBRARIES
    char *originalLibrariesPath = getenv("ChaxOriginalInsertLibraries");
    
    if (originalLibrariesPath) {
        setenv("DYLD_INSERT_LIBRARIES", originalLibrariesPath, 1);
    } else {
        unsetenv("DYLD_INSERT_LIBRARIES");
    }
    
	return [[NSBundle bundleWithIdentifier:@"com.ksuther.chax"] bundleURL];
}

DYLD_INTERPOSE(_ChaxURLToIChatApp, URLToIChatApp);
