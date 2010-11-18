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
@protocol ECTwitterEngineHandler
@optional

- (void) twitterEngine: (ECTwitterEngine*) engine failedWithError: (NSError*) error;
- (void) twitterEngine: (ECTwitterEngine*) engine didReceiveTweets: (NSArray*) tweets;
- (void) twitterEngine: (ECTwitterEngine*) engine didReceiveUsers: (NSArray*) users;
- (void) twitterEngine: (ECTwitterEngine*) engine didAuthenticateWithToken: (OAToken*) token;
- (void) twitterEngine: (ECTwitterEngine*) engine didReceiveUserIds: (NSArray*) ids nextCursor: (MGTwitterEngineCursorID) next previousCursor: (MGTwitterEngineCursorID) previous;
- (void) twitterEngine: (ECTwitterEngine*) engine didReceiveGeoResults: (NSArray*) places forQuery: (NSDictionary*) query;

@end

// --------------------------------------------------------------------------
//! Higher level wrapper for MGTwitterEngine.
// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate, ECTwitterEngineHandler> 
{

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
- (void) authenticateForUser: (NSString*) user password: (NSString*) password handler: (NSObject<ECTwitterEngineHandler>*) handler;
- (BOOL) isAuthenticated;
- (void) setHandler: (NSObject<ECTwitterEngineHandler>*) handler forRequest: (NSString*) request;

- (void) getGeoSearchAt: (CLLocation*) location handler: (NSObject<ECTwitterEngineHandler>*) handler;

// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterAuthenticationSucceeded;
extern NSString *const TwitterAuthenticationFailed;
extern NSString *const TwitterReceivedLocateTweets;

@end
