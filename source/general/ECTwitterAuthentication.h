// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 07/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class OAToken;
@class ECTwitterHandler;
@class ECTwitterEngine;
@class ECTwitterConnection;

extern NSString *const TwitterAuthenticationSucceeded;
extern NSString *const TwitterAuthenticationFailed;

@interface ECTwitterAuthentication : NSObject

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) ECTwitterConnection* connection;
@property (nonatomic, retain) NSString* consumerKey;
@property (nonatomic, retain) NSString* consumerSecret;
@property (nonatomic, retain) ECTwitterEngine* engine;
@property (nonatomic, retain) ECTwitterHandler* handler;
@property (nonatomic, retain) OAToken* token;
@property (nonatomic, retain) NSString* username;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;
- (BOOL) isAuthenticated;
- (BOOL) authenticateForUser: (NSString*) user;
- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector;
- (NSMutableURLRequest*) requestForURL:(NSURL*)url;

@end
