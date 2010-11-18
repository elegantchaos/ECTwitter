// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterHandler.h"


// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterHandler()

@end


@implementation ECTwitterHandler

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(operation);
ECPropertySynthesize(status);
ECPropertySynthesize(engine);

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Methods
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
//! Return the handler for a request id.
// --------------------------------------------------------------------------

- (void) invokeWithStatus: (ECTwitterStatus) status
{
	self.status = status;
	[[NSOperationQueue mainQueue] addOperation: self.operation];
}

- (void) dealloc
{
	ECPropertyDealloc(operation);
	ECPropertyDealloc(engine);
	
	[super dealloc];
}
@end
