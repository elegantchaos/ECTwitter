// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
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

// --------------------------------------------------------------------------
//! Higher level wrapper for MGTwitterEngine.
// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate> 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) ECTwitterAuthentication* authentication;
@property (nonatomic, retain) MGTwitterEngine* engine;
@property (nonatomic, retain) NSMutableDictionary* requests;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithAuthetication:(ECTwitterAuthentication *)authenticationIn clientName:(NSString*)clientName version:(NSString*)clientVersion url:(NSURL*)clientURL;

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector;
- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector;
- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

- (void)registerError:(NSError*)error inContext:(NSObject*)context;


// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const TwitterReceivedLocateTweets;

@end
