// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

typedef enum 
{
	StatusSucceeded,
	StatusResults,
	StatusFailed,
} ECTwitterStatus;

@class ECTwitterEngine;

@interface ECTwitterHandler : NSObject 
{
	ECPropertyVariable(operation, NSOperation*);
	ECPropertyVariable(status, ECTwitterStatus);
	ECPropertyVariable(engine, ECTwitterEngine*);

}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(operation, NSOperation*);
ECPropertyRetained(engine, ECTwitterEngine*);
ECPropertyAssigned(status, ECTwitterStatus);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithEngine: (ECTwitterEngine*) engine target: (id) target selector: (SEL) selector;
- (void) invokeWithStatus: (ECTwitterStatus) status;

@end
