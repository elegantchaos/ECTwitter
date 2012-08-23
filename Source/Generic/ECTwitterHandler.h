// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 18/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

- (id)initWithEngine:(ECTwitterEngine*)engine target:(id)target selector:(SEL)selector;
- (id)initWithEngine:(ECTwitterEngine*)engine handler:(void (^)(ECTwitterHandler*))handler;
- (void)invokeWithStatus:(ECTwitterStatus) status;
- (void)invokeWithResult:(id)result;

- (NSString*)errorString;

@end
