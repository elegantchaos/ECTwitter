// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 07/04/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

@property (strong, nonatomic) ECTwitterConnection* connection;
@property (strong, nonatomic) NSString* consumerKey;
@property (strong, nonatomic) NSString* consumerSecret;
@property (strong, nonatomic) ECTwitterEngine* engine;
@property (strong, nonatomic) ECTwitterHandler* handler;
@property (strong, nonatomic) OAToken* token;
@property (strong, nonatomic) NSString* username;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithKey:(NSString*)key secret:(NSString*)secret;
- (BOOL)isAuthenticated;
- (BOOL)authenticateForUser:(NSString*)user;
- (void)authenticateForUser:(NSString*)user password:(NSString*)password target:(id) target selector:(SEL)selector;
- (void)authenticateForUser:(NSString*)user password:(NSString*)password handler:(void (^)(ECTwitterHandler* handler))handler;

- (NSMutableURLRequest*)requestForURL:(NSURL*)url;

@end
