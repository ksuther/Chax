/*
 * AutomaticSwizzle.m
 *
 * Copyright (c) 2007- Kent Sutherland
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

#import "AutomaticSwizzle.h"
#import <objc/objc-class.h>

const char *ChaxMethodSwizzlePrefix = "chax_swizzle_";

void PerformAutomaticSwizzle()
{
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
}

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
			MethodSwizzleClass(swizzleTargetClass, sel_registerName(name + strlen(ChaxMethodSwizzlePrefix)), selector);
		}
	}
	free(methods);
	
	[pool release];
}

@end
