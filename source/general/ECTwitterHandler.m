// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterHandler.h"


// ==============================================
// Private Methods
// ==============================================

@interface ECTwitterHandler()

@end


@implementation ECTwitterHandler

// ==============================================
// Properties
// ==============================================

ECPropertySynthesize(operation);
ECPropertySynthesize(status);
ECPropertySynthesize(results);
ECPropertySynthesize(engine);
ECPropertySynthesize(extra);

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle methods

// --------------------------------------------------------------------------
//! Initialise a handler to call a selector on a target.
// --------------------------------------------------------------------------

- (id) initWithEngine: (ECTwitterEngine*) engine target: (id) target selector: (SEL) selector
{
	if ((self = [super init]) != nil)
	{
		NSOperation* operation = [[NSInvocationOperation alloc] initWithTarget: target selector: selector object: self];
		self.operation = operation;
		self.engine = engine;
		[operation release];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(operation);
	ECPropertyDealloc(engine);
	ECPropertyDealloc(results);
	ECPropertyDealloc(extra);

	[super dealloc];
}

// ==============================================
// Invocation
// ==============================================

#pragma mark -
#pragma mark Invocation methods

// --------------------------------------------------------------------------
//! Invoke the handler with a given status.
// --------------------------------------------------------------------------

- (void) invokeWithStatus: (ECTwitterStatus) status
{
	self.status = status;
	[[NSOperationQueue mainQueue] addOperation: self.operation];
}

// --------------------------------------------------------------------------
//! Invoke the handler with a given result object.
// --------------------------------------------------------------------------

- (void) invokeWithResults: (NSObject*) results
{
	self.results = results;
	[self invokeWithStatus: StatusResults];
}

// --------------------------------------------------------------------------
//! Return the results cast to an array.
// --------------------------------------------------------------------------

- (NSArray*) resultsAsArray
{
	return (NSArray*) self.results;
}

@end
