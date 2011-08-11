// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <ECFoundation/ECProperties.h>

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
	ECPropertyVariable(result, id);
	ECPropertyVariable(extra, id);
	ECPropertyVariable(error, NSError*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(operation, NSOperation*);
ECPropertyRetained(engine, ECTwitterEngine*);
ECPropertyRetained(result, id);
ECPropertyAssigned(status, ECTwitterStatus);
ECPropertyRetained(extra, id);
ECPropertyRetained(error, NSError*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithEngine: (ECTwitterEngine*) engine target: (id) target selector: (SEL) selector;
- (void) invokeWithStatus: (ECTwitterStatus) status;
- (void) invokeWithResult: (id) result;

- (NSString*) errorString;

@end
