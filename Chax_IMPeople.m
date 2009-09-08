/*
 * Chax_IMPeople.m
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

#import "Chax_IMPeople.h"
#import "UnifiedPeopleListController_Provider.h"

@implementation Chax_IMPeople

- (BOOL)chax_swizzle_addIMHandle:(id)fp8
{
	NSArray *existingHandles = [[[NSClassFromString(@"UnifiedPeopleListController") sharedController] sourcePeople] people];
	
	for (IMHandle *nextHandle in existingHandles) {
		if ([nextHandle compareIDs:fp8] == NSOrderedSame) {
			//Don't add the presentity if the same user was already added on another service
			return [self chax_swizzle_addIMHandle:fp8];
		}
	}
	
	[[[NSClassFromString(@"UnifiedPeopleListController") sharedController] sourcePeople] chax_swizzle_addIMHandle:fp8];
    
	return [self chax_swizzle_addIMHandle:fp8];
}

- (BOOL)chax_swizzle_removeIMHandle:(id)fp8
{
	NSArray *controllers = [NSClassFromString(@"PeopleListController") peopleListControllers];
	
	for (PeopleListController *plc in controllers) {
		if (self != [plc sourcePeople] && plc != [NSClassFromString(@"UnifiedPeopleListController") sharedController]) {
			NSArray *handles = [[plc sourcePeople] people];
			
			for (IMHandle *nextHandle in handles) {
				if ([nextHandle compareIDs:fp8] == NSOrderedSame) {
					//Don't remove the presentity if the same user is on another service's contact list
					[[[NSClassFromString(@"UnifiedPeopleListController") sharedController] sourcePeople] chax_swizzle_removeIMHandle:fp8];
					[[[NSClassFromString(@"UnifiedPeopleListController") sharedController] sourcePeople] chax_swizzle_addIMHandle:nextHandle];
					
					return [self chax_swizzle_removeIMHandle:fp8];
				}
			}
		}
	}
	
	[[[NSClassFromString(@"UnifiedPeopleListController") sharedController] sourcePeople] chax_swizzle_removeIMHandle:fp8];
    
	return [self chax_swizzle_removeIMHandle:fp8];
}

@end
