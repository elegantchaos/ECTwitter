// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 14/12/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@class ECTwitterEngine;
@class ECTwitterCache;

@interface ECTwitterCachedObject : NSObject 

/// The cache that this object belongs to.

@property (assign, nonatomic) ECTwitterCache* cache; // weak reference

// --------------------------------------------------------------------------
/// @name Initialising an ECTwitterCachedObject Instance
// --------------------------------------------------------------------------

/// Create an object and associate it with a cache.
///
/// @param cache The cache that this object lives in.

- (id) initWithCache:(ECTwitterCache*)cache;

// --------------------------------------------------------------------------
// @name Getting Information About The Object
// --------------------------------------------------------------------------

/// The engine that this object is associated with.
/// @return The engine that this object's cache is attached to.

- (ECTwitterEngine*)engine;

@end
