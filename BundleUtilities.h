//
//  BundleUtilities.h
//  Chax
//
//  Created by Kent Sutherland on 7/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BundleUtilities : NSObject {
}

+ (Class)subclass:(Class)baseClass usingClassName:(NSString*)subclassName providerClass:(Class)providerClass;
+ (void)extendClass:(Class) targetClass withMethodsFromClass:(Class)providerClass;
+ (BOOL)addClassMethodName:(NSString *)methodName fromProviderClass:(Class)providerClass toClass:(Class)targetClass;
+ (BOOL)addInstanceMethodName:(NSString *)methodName fromProviderClass:(Class)providerClass toClass:(Class)targetClass;

@end