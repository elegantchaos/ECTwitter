// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 18/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
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

@synthesize engine = _engine;
@synthesize error = _error;
@synthesize extra = _extra;
@synthesize operation = _operation;
@synthesize result = _result;
@synthesize status = _status;

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle methods

// --------------------------------------------------------------------------
/// Initialise a handler to call a selector on a target.
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
/// Initialise a handler to call a block.
// --------------------------------------------------------------------------

- (id) initWithEngine:(ECTwitterEngine*)engineIn handler:(ECTwitterHandlerBlock)handler
{
    ECTwitterHandlerBlock handlerCopy = [handler copy];
	if ((self = [super init]) != nil)
	{
        NSOperation* newOperation = [NSBlockOperation blockOperationWithBlock:^{
            handlerCopy(self);
        }];
		self.operation = newOperation;
		self.engine = engineIn;
	}

    [handlerCopy release];

	return self;
}

// --------------------------------------------------------------------------
/// Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	[_operation release];
	[_engine release];
	[_result release];
	[_extra release];
	[_error release];

	[super dealloc];
}

// ==============================================
// Invocation
// ==============================================

#pragma mark -
#pragma mark Invocation methods

// --------------------------------------------------------------------------
/// Invoke the handler with a given status.
// --------------------------------------------------------------------------

- (void) invokeWithStatus:(ECTwitterStatus)statusIn
{
	self.status = statusIn;
	[[NSOperationQueue mainQueue] addOperation:self.operation];
    self.operation = nil;
}

// --------------------------------------------------------------------------
/// Invoke the handler with a given result object.
// --------------------------------------------------------------------------

- (void) invokeWithResult:(id)resultIn
{
	self.result = resultIn;
	[self invokeWithStatus: StatusResults];
}

// --------------------------------------------------------------------------
/// Return an error string.
// --------------------------------------------------------------------------

- (NSString*)errorString
{
	return [self.error localizedDescription];
}

- (NSString*)description
{
    if (self.status == StatusFailed)
    {
        return [NSString stringWithFormat:@"<ECTwitterHandler error:%@>", self.errorString];
    }
    else
    {
        return [NSString stringWithFormat:@"<ECTwitterHandler result:%@>", self.result];
    }
}

@end
