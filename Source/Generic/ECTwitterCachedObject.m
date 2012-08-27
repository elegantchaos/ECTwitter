// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 14/12/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"
#import "ECTwitterCache.h"
#import "ECTwitterEngine.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterCachedObject()

@end


@implementation ECTwitterCachedObject

@synthesize cache = _cache;

// ==============================================
// Properties
// ==============================================

#pragma mark -
#pragma mark Properties

// ==============================================
// Constants
// ==============================================

#pragma mark -
#pragma mark Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Methods

// --------------------------------------------------------------------------
/// Set up the object.
// --------------------------------------------------------------------------

- (id) initWithCache:(ECTwitterCache*)cache
{
	if ((self = [super init]) != nil)
	{
		self.cache = cache;
	}
	
	return self;
}


// --------------------------------------------------------------------------
/// Return our cache's engine.
// --------------------------------------------------------------------------

- (ECTwitterEngine*)engine
{
    return self.cache.engine;
}

@end
