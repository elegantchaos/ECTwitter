// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Status Values
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
	ECPropertyVariable(results, NSObject*);
	ECPropertyVariable(extra, NSObject*);

}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(operation, NSOperation*);
ECPropertyRetained(engine, ECTwitterEngine*);
ECPropertyRetained(results, NSObject*);
ECPropertyAssigned(status, ECTwitterStatus);
ECPropertyRetained(extra, NSObject*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithEngine: (ECTwitterEngine*) engine target: (id) target selector: (SEL) selector;
- (void) invokeWithStatus: (ECTwitterStatus) status;
- (void) invokeWithResults: (NSObject*) results;

- (NSArray*) resultsAsArray;

@end
