// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
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
    ECPropertyVariable(authRequest, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(engine, MGTwitterEngine*);
ECPropertyRetained(token, OAToken*);
ECPropertyRetained(requests, NSMutableDictionary*);
ECPropertyRetained(authRequest, NSString*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;

- (BOOL) authenticateForUser: (NSString*) user;
- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector;

- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

- (BOOL) isAuthenticated;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterAuthenticationSucceeded;
extern NSString *const TwitterAuthenticationFailed;
extern NSString *const TwitterReceivedLocateTweets;

@end
