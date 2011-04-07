// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 07/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class OAToken;
@class ECTwitterHandler;
@class ECTwitterEngine;
@class MGTwitterHTTPURLConnection;

@interface ECTwitterAuthentication : NSObject
{
    ECPropertyVariable(connection, MGTwitterHTTPURLConnection*);
    ECPropertyVariable(consumerKey, NSString*);
    ECPropertyVariable(consumerSecret, NSString*);
    ECPropertyVariable(engine, ECTwitterEngine*);
    ECPropertyVariable(handler, ECTwitterHandler*);
    ECPropertyVariable(token, OAToken*);
    ECPropertyVariable(username, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(connection, MGTwitterHTTPURLConnection*);
ECPropertyRetained(consumerKey, NSString*);
ECPropertyRetained(consumerSecret, NSString*);
ECPropertyRetained(engine, ECTwitterEngine*);
ECPropertyRetained(handler, ECTwitterHandler*);
ECPropertyRetained(token, OAToken*);
ECPropertyRetained(username, NSString*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;
- (BOOL) isAuthenticated;
- (BOOL) authenticateForUser: (NSString*) user;
- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector;
- (NSMutableURLRequest*) requestForURL:(NSURL*)url;

@end
