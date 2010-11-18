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
- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector ;
- (BOOL) isAuthenticated;
- (void) setHandler: (ECTwitterHandler*) handler forRequest: (NSString*) request;
//- (void) getGeoSearchAt: (CLLocation*) location handler: (ECTwitterHandler) handler;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterAuthenticationSucceeded;
extern NSString *const TwitterAuthenticationFailed;
extern NSString *const TwitterReceivedLocateTweets;

@end
