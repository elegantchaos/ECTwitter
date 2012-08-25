// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterHandlerBlock.h"

// --------------------------------------------------------------------------
// Status Values
// --------------------------------------------------------------------------

typedef enum 
{
	StatusSucceeded,
	StatusResults,
	StatusFailed,
} ECTwitterStatus;

@class ECTwitterHandler;
@class ECTwitterEngine;

@interface ECTwitterHandler : NSObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (strong, nonatomic) ECTwitterEngine* engine;
@property (strong, nonatomic) NSError* error;
@property (strong, nonatomic) id extra;
@property (strong, nonatomic) NSOperation* operation;
@property (strong, nonatomic) id result;
@property (nonatomic, assign) ECTwitterStatus status;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)initWithEngine:(ECTwitterEngine*)engine target:(id)target selector:(SEL)selector;
- (id)initWithEngine:(ECTwitterEngine*)engine handler:(ECTwitterHandlerBlock)handler;
- (void)invokeWithStatus:(ECTwitterStatus) status;
- (void)invokeWithResult:(id)result;

- (NSString*)errorString;

@end
