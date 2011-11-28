// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

@synthesize engine;
@synthesize error;
@synthesize extra;
@synthesize operation;
@synthesize result;
@synthesize status;

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle methods

// --------------------------------------------------------------------------
//! Initialise a handler to call a selector on a target.
// --------------------------------------------------------------------------

- (id) initWithEngine:(ECTwitterEngine*)engineIn target:(id)target selector:(SEL)selector
{
	if ((self = [super init]) != nil)
	{
		NSOperation* newOperation = [[NSInvocationOperation alloc] initWithTarget: target selector: selector object: self];
		self.operation = newOperation;
		self.engine = engineIn;
		[newOperation release];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	[operation release];
	[engine release];
	[result release];
	[extra release];
	[error release];

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

- (void) invokeWithStatus:(ECTwitterStatus)statusIn
{
	self.status = statusIn;
	[[NSOperationQueue mainQueue] addOperation: self.operation];
}

// --------------------------------------------------------------------------
//! Invoke the handler with a given result object.
// --------------------------------------------------------------------------

- (void) invokeWithResult:(id)resultIn
{
	self.result = resultIn;
	[self invokeWithStatus: StatusResults];
}

// --------------------------------------------------------------------------
//! Return an error string.
// --------------------------------------------------------------------------

- (NSString*) errorString
{
	return [self.error localizedDescription];
}

@end
