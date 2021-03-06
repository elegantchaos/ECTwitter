// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 13/09/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "MGTwitterEngineDelegate.h"

// --------------------------------------------------------------------------
// Handler Protocol.
// --------------------------------------------------------------------------

@class MGTwitterEngine;
@class ECTwitterEngine;
@class ECTwitterHandler;
@class ECTwitterAuthentication;

/// --------------------------------------------------------------------------
/// Simple Twitter Engine
/// This engine exposes fairly raw access to the twitter api, but
/// manages the process of sending requests, and parsing results.
/// For each twitter call that you make, you supply a block (or target & selector)
/// which the engine calls back when the call succeeds or fails.
/// Authentication is dealy with via the @ECAuthentication helper class.
/// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate> 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (strong, nonatomic) ECTwitterAuthentication* authentication;
@property (strong, nonatomic) NSString* consumerKey;
@property (strong, nonatomic) NSString* consumerSecret;
@property (strong, nonatomic) MGTwitterEngine* engine;
@property (strong, nonatomic) NSMutableDictionary* requests;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithConsumerKey:(NSString*)consumerKey consumerSecret:(NSString*)consumerSecret clientName:(NSString*)clientName version:(NSString*)clientVersion url:(NSURL*)clientURL;

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector;
- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector;
- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters handler:(void (^)(ECTwitterHandler* handler))handler;
- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler;

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters handler:(void (^)(ECTwitterHandler* handler))handler;
- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler;

- (void)registerError:(NSError*)error inContext:(NSObject*)context;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterReceivedLocateTweets;

@end
