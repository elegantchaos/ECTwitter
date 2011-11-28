// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "MGTwitterEngineDelegate.h"

#import <ECFoundation/ECProperties.h>

// --------------------------------------------------------------------------
// Handler Protocol.
// --------------------------------------------------------------------------

@class MGTwitterEngine;
@class ECTwitterEngine;
@class ECTwitterHandler;
@class ECTwitterAuthentication;

// --------------------------------------------------------------------------
//! Higher level wrapper for MGTwitterEngine.
// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate> 
{
	ECPropertyVariable(engine, MGTwitterEngine*);
    ECPropertyVariable(authentication, ECTwitterAuthentication*);
	ECPropertyVariable(requests, NSMutableDictionary*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(engine, MGTwitterEngine*);
ECPropertyRetained(authentication, ECTwitterAuthentication*);
ECPropertyRetained(requests, NSMutableDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithAuthetication:(ECTwitterAuthentication*)authentication;

- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

- (void)registerError:(NSError*)error inContext:(NSObject*)context;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterReceivedLocateTweets;

@end
