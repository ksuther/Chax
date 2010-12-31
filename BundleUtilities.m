/*
 * BundleUtilities.m
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

#import "BundleUtilities.h"
#import <objc/objc.h>
#import <objc/runtime.h>

@implementation BundleUtilities

+ (Class)subclass:(Class)baseClass usingClassName:(NSString*)subclassName providerClass:(Class)providerClass
{
	Class subclass = objc_allocateClassPair(baseClass, [subclassName UTF8String], 0);
	if (!subclass) return nil;
	
	unsigned int ivarCount =0;
	Ivar * ivars = class_copyIvarList(providerClass, &ivarCount);
	int ci = 0;
	for (ci=0 ;ci < ivarCount; ci++){
		Ivar anIvar = ivars[ci];
		
		NSUInteger ivarSize = 0;
		NSUInteger ivarAlignment = 0;
		const char * typeEncoding = ivar_getTypeEncoding(anIvar);
		NSGetSizeAndAlignment(typeEncoding, &ivarSize, &ivarAlignment);
		const char * ivarName = ivar_getName(anIvar);
		
		BOOL addIVarResult = class_addIvar(subclass, ivarName, ivarSize, ivarAlignment, typeEncoding  );
		if (!addIVarResult){
			NSLog(@"could not add iVar %s", ivar_getName(anIvar));
			return nil;
		}
		
	}
	free(ivars);
	objc_registerClassPair(subclass);
	
	[self extendClass:subclass withMethodsFromClass:providerClass];
	return subclass;
}

+ (void)extendClass:(Class) targetClass withMethodsFromClass:(Class)providerClass
{
	unsigned int methodCount = 0;
	Method * methods = nil;
	
	// extend instance Methods
	methods = class_copyMethodList(providerClass, &methodCount);
	int ci= methodCount;
	while (methods && ci--){
		NSString * methodName = NSStringFromSelector(method_getName(methods[ci]));
		[self addInstanceMethodName:methodName fromProviderClass:providerClass toClass:targetClass];
		//NSLog(@"extending -[%s %@]",class_getName(targetClass),methodName);
	}
	free(methods);
	
	// extend Class Methods
	methods = class_copyMethodList(object_getClass(providerClass), &methodCount);
	ci= methodCount;
	while (methods && ci--){
		NSString * methodName = NSStringFromSelector(method_getName(methods[ci]));
		[self addClassMethodName:methodName fromProviderClass:providerClass toClass:targetClass];
		//NSLog(@"extending +[%s %@]",class_getName(targetClass),methodName);
	}
	free(methods);
	
	methods  = 0;
}

+ (BOOL)addClassMethodName:(NSString *)methodName fromProviderClass:(Class)providerClass toClass:(Class)targetClass
{
	Class metaClass = object_getClass(targetClass);// objc_getMetaClass(class_getName(targetClass));
	if (!metaClass) {
		return NO;
	}
	SEL selector = NSSelectorFromString(methodName);
	Method originalMethod = class_getClassMethod(providerClass,selector);
	
	if (!originalMethod) {
		return NO;
	}
	
	IMP originalImplementation  = method_getImplementation(originalMethod);
	if (!originalImplementation){
		return NO;
	}
	
	class_addMethod(metaClass, selector ,originalImplementation, method_getTypeEncoding(originalMethod));
	
	return YES;
}

+ (BOOL)addInstanceMethodName:(NSString *)methodName fromProviderClass:(Class)providerClass toClass:(Class)targetClass
{
	if (!targetClass) {
		return NO;
	}
	SEL selector = NSSelectorFromString(methodName);
	Method originalMethod = class_getInstanceMethod(providerClass,selector);
	
	if (!originalMethod) {
		return NO;
	}
	
	IMP originalImplementation = method_getImplementation(originalMethod);
	if (!originalImplementation){
		return NO;
	}
	
	class_addMethod(targetClass, selector, originalImplementation, method_getTypeEncoding(originalMethod));
	
	return YES;
}

@end
