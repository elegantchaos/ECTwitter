// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
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

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) ECTwitterEngine* engine;
@property (nonatomic, retain) NSError* error;
@property (nonatomic, retain) id extra;
@property (nonatomic, retain) NSOperation* operation;
@property (nonatomic, retain) id result;
@property (nonatomic, assign) ECTwitterStatus status;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithEngine: (ECTwitterEngine*) engine target: (id) target selector: (SEL) selector;
- (void) invokeWithStatus: (ECTwitterStatus) status;
- (void) invokeWithResult: (id) result;

- (NSString*) errorString;

@end
