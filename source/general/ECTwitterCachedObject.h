// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 14/12/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class ECTwitterEngine;
@class ECTwitterCache;

@interface ECTwitterCachedObject : NSObject 
{
@protected
	ECTwitterCache*	mCache;
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

- (id) initWithCache: (ECTwitterCache*) cache;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (ECTwitterEngine*)engine;

@end
