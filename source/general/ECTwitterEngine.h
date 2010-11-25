// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "MGTwitterEngine.h"

// --------------------------------------------------------------------------
// Handler Protocol.
// --------------------------------------------------------------------------

@class ECTwitterEngine;
@class ECTwitterHandler;

// --------------------------------------------------------------------------
//! Higher level wrapper for MGTwitterEngine.
// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate> 
{
	ECPropertyVariable(engine, MGTwitterEngine*);
	ECPropertyVariable(token, OAToken*);
	ECPropertyVariable(requests, NSMutableDictionary*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(engine, MGTwitterEngine*);
ECPropertyRetained(token, OAToken*);
ECPropertyRetained(requests, NSMutableDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;
- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector;
- (void) callMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
- (void) callMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

- (BOOL) isAuthenticated;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterAuthenticationSucceeded;
extern NSString *const TwitterAuthenticationFailed;
extern NSString *const TwitterReceivedLocateTweets;

@end
