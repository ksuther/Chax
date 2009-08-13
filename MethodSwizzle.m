/*
 * MethodSwizzle.m
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

#import "MethodSwizzle.h"
#import <objc/objc-class.h>

const char *ChaxMethodSwizzlePrefix = "chax_swizzle_";

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
    Method orig_method = nil, alt_method = nil;
	
    // First, look for the methods
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);
	
    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil)) {
        method_exchangeImplementations(orig_method, alt_method);
	}
}

void MethodSwizzleClass(Class aClass, SEL orig_sel, SEL alt_sel)
{
    Method orig_method = nil, alt_method = nil;
	
    // First, look for the methods
    orig_method = class_getClassMethod(aClass, orig_sel);
    alt_method = class_getClassMethod(aClass, alt_sel);
	
    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil)) {
        method_exchangeImplementations(orig_method, alt_method);
	}
}

#pragma mark -

@implementation NSObject (MethodSwizzle)

+ (void)swizzleMethods
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	Class swizzleTargetClass = NSClassFromString([NSStringFromClass([self class]) substringFromIndex:5]);
	
	[BundleUtilities extendClass:swizzleTargetClass withMethodsFromClass:self];
	
	unsigned int methodCount = 0;
	Method *methods = nil;
	
	//Handle instance methods
	methods = class_copyMethodList(swizzleTargetClass, &methodCount);
	int ci = methodCount;
	while (methods && ci--){
		SEL selector = method_getName(methods[ci]);
		const char *name = sel_getName(selector);
		
		if (strncmp(name, ChaxMethodSwizzlePrefix, strlen(ChaxMethodSwizzlePrefix)) == 0) {
			MethodSwizzle(swizzleTargetClass, sel_registerName(name + strlen(ChaxMethodSwizzlePrefix)), selector);
		}
	}
	free(methods);
	
	//Handle class methods
	methods = class_copyMethodList(object_getClass(swizzleTargetClass), &methodCount);
	ci = methodCount;
	while (methods && ci--){
		SEL selector = method_getName(methods[ci]);
		const char *name = sel_getName(selector);
		
		if (strncmp(name, ChaxMethodSwizzlePrefix, strlen(ChaxMethodSwizzlePrefix)) == 0) {
			MethodSwizzle(swizzleTargetClass, sel_registerName(name + strlen(ChaxMethodSwizzlePrefix)), selector);
		}
	}
	free(methods);
	
	[pool release];
}

@end

#pragma mark -
#pragma mark NSApplication Override

#define DYLD_INTERPOSE(_replacment,_replacee) \
__attribute__((used)) static struct{ const void* replacment; const void* replacee; } _interpose_##_replacee \
__attribute__ ((section ("__DATA,__interpose"))) = { (const void*)(unsigned long)&_replacment, (const void*)(unsigned long)&_replacee };

static int _ChaxApplicationMain(int argc, const char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSUInteger numClasses;
	Class *classes = NULL;
	
	classes = NULL;
	numClasses = objc_getClassList(NULL, 0);
	
	if (numClasses > 0) {
		classes = malloc(sizeof(Class) * numClasses);
		numClasses = objc_getClassList(classes, numClasses);
		
		for (NSUInteger i = 0; i < numClasses; i++) {
			if (strncmp(class_getName(classes[i]), "Chax_", 5) == 0) {
				[classes[i] swizzleMethods];
			}
		}
		
		free(classes);
	}
	
	[pool release];
	
    char *librariesPath = getenv("DYLD_INSERT_LIBRARIES");
    char *originalLibrariesPath = getenv("ChaxOriginalInsertLibraries");
    
    if (originalLibrariesPath) {
        setenv("DYLD_INSERT_LIBRARIES", originalLibrariesPath, 1);
    } else {
        unsetenv("DYLD_INSERT_LIBRARIES");
    }
    
	return NSApplicationMain(argc, argv);
}

DYLD_INTERPOSE(_ChaxApplicationMain, NSApplicationMain);
