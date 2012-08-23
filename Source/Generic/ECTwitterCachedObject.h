// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 14/12/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

- (id) initWithCache:(ECTwitterCache*)cache;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (ECTwitterEngine*)engine;
- (ECTwitterCache*)cache;

@end
