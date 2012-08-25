/// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
/// --------------------------------------------------------------------------

#import "MGTwitterEngineDelegate.h"
#import "ECTwitterHandlerBlock.h"

@class ECTwitterEngine;
@class ECTwitterHandler;
@class ECTwitterAuthentication;

/// --------------------------------------------------------------------------
/// A simple Twitter engine.
///
/// This engine exposes fairly raw access to the twitter api, but
/// manages the process of sending requests, and parsing results.
///
/// For each twitter call that you make, you supply a block (or target & selector)
/// which the engine calls back when the call succeeds or fails.
///
/// Authentication is dealt with via the <ECTwitterAuthentication> helper class.
/// --------------------------------------------------------------------------

@interface ECTwitterEngine : NSObject <MGTwitterEngineDelegate> 

/// --------------------------------------------------------------------------
/// @name Properties
/// --------------------------------------------------------------------------

/// The object responsible for performing authentication.

@property (strong, nonatomic) ECTwitterAuthentication* authentication;

/// The Twitter key for the client application.

@property (strong, nonatomic) NSString* consumerKey;

/// The Twitter secret for the client application.

@property (strong, nonatomic) NSString* consumerSecret;


/// --------------------------------------------------------------------------
/// @name Creation
/// --------------------------------------------------------------------------

/**
 * Create an instance of the engine.
 * Typically you only need one instance per application.
 *
 * @param consumerKey Twitter key for your application.
 * @param consumerSecret Twitter secret for your application.
 * @param clientName Name of your application (as displayed by Twitter clients).
 * @param clientVersion Version of your application (as displayed by Twitter clients).
 * @param clientURL Website for your application (as displayed by Twitter clients).
 * @return A new engine instance.
 */

- (id) initWithConsumerKey:(NSString*)consumerKey consumerSecret:(NSString*)consumerSecret clientName:(NSString*)clientName version:(NSString*)clientVersion url:(NSURL*)clientURL;

/// --------------------------------------------------------------------------
/// Call a twitter method, using http GET.
///
/// When it's done, the engine will call back to the specified target/selector.
/// @param method The twitter method to call.
/// @param parameters A dictionary of parameters to pass to Twitter.
/// @param target Object to call back with the results.
/// @param selector Selector to call with the results.
/// @param extra Extra data to be passed back with the results (can be nil).
/// --------------------------------------------------------------------------

/// --------------------------------------------------------------------------
/// @name Twitter API
/// --------------------------------------------------------------------------

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

/// --------------------------------------------------------------------------
/// Call a twitter method, using http POST.
///
/// When it's done, the engine will call back to the specified target/selector.
/// @param method The twitter method to call.
/// @param parameters A dictionary of parameters to pass to Twitter.
/// @param target Object to call back with the results.
/// @param selector Selector to call with the results.
/// @param extra Extra data to be passed back with the results (can be nil).
/// --------------------------------------------------------------------------

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra;

/// --------------------------------------------------------------------------
/// Call a twitter method, using http GET.
///
/// When it's done, the engine will call back to the specified target/selector.
/// @param method The twitter method to call.
/// @param parameters A dictionary of parameters to pass to Twitter.
/// @param extra Extra data to be passed back with the results (can be nil).
/// @param handler Handler block to call back with the results.
/// --------------------------------------------------------------------------

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(ECTwitterHandlerBlock)handler;

/// --------------------------------------------------------------------------
/// Call a twitter method, using http POST.
///
/// When it's done, the engine will call back to the specified target/selector.
/// @param method The twitter method to call.
/// @param parameters A dictionary of parameters to pass to Twitter.
/// @param extra Extra data to be passed back with the results (can be nil).
/// @param handler Handler block to call back with the results.
/// --------------------------------------------------------------------------

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(ECTwitterHandlerBlock)handler;

/// --------------------------------------------------------------------------
/// @name Error Reporting
/// --------------------------------------------------------------------------

/// --------------------------------------------------------------------------
/// Report an error to the engine.
///
/// The engine chooses whether to report the error to the user,
/// log it, or whatever.
///
/// @param error The error to report.
/// @param context An object (can be a string) describing the context in which the error occurred.
/// --------------------------------------------------------------------------

- (void)registerError:(NSError*)error inContext:(NSObject*)context;


@end
