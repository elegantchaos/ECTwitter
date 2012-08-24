// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 13/09/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterEngine.h"
#import "ECTwitterTweet.h"
#import "ECTwitterUser.h"
#import "ECTwitterPlace.h"
#import "ECTwitterHandler.h"
#import "ECTwitterAuthentication.h"
#import "MGTwitterEngine.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterEngine()

- (void)setHandler:(ECTwitterHandler*)handler forRequest:(NSString*)request;
- (ECTwitterHandler*)handlerForRequest:(NSString*)request;
- (void)doneRequest:(NSString*)request;
- (void)callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters target:(id)target selector:(SEL)selector extra:(NSObject*)extra;
- (void) callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler;

@end

@implementation ECTwitterEngine


// --------------------------------------------------------------------------
// Debug Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(TwitterChannel);
ECDeclareLogChannel(ErrorChannel);

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

@synthesize authentication;
@synthesize engine;
@synthesize requests;

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle

// --------------------------------------------------------------------------
/// Initialise the engine.
// --------------------------------------------------------------------------

- (id)initWithAuthetication:(ECTwitterAuthentication *)authenticationIn clientName:(NSString*)clientName version:(NSString*)clientVersion url:(NSURL*)clientURL
{
	if ((self = [super init]) != nil)
	{
		MGTwitterEngine* newEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
        [newEngine setClientName:clientName version:clientVersion URL:[clientURL absoluteString]];
        self.authentication = authenticationIn;
        authentication.engine = self;
		self.engine = newEngine;
        
		[newEngine release];
        
		self.requests = [NSMutableDictionary dictionary];

		ECDebug(TwitterChannel, @"initialised engine");
	}
	
	return self;
}


// --------------------------------------------------------------------------
/// Clean up and release references.
// --------------------------------------------------------------------------

- (void) dealloc 
{
    [authentication release];
	[engine release];
	[requests release];
    
    [super dealloc];
}



// ==============================================
// Request Handling
// ==============================================

#pragma mark -
#pragma mark Request Handling

// --------------------------------------------------------------------------
/// Remember a request id and associate it with a handler.
// --------------------------------------------------------------------------

- (void) setHandler:(ECTwitterHandler*)handler forRequest:(NSString*)request
{
	[self.requests setObject: handler forKey: request];
}

// --------------------------------------------------------------------------
/// Return the handler for a request id.
// --------------------------------------------------------------------------

- (ECTwitterHandler*)handlerForRequest:(NSString*)request
{
	return [self.requests objectForKey: request];
}

// --------------------------------------------------------------------------
/// Clear a request from our list.
// --------------------------------------------------------------------------

- (void) doneRequest:(NSString*)request
{
	ECTwitterHandler* handler = [self.requests objectForKey: request];
	handler.operation = nil;
	[self.requests removeObjectForKey: request];
}

// --------------------------------------------------------------------------
// MGTwitterEngineDelegate Methods
// --------------------------------------------------------------------------

#pragma mark -
#pragma mark MGTwitterEngineDelegate Methods

// --------------------------------------------------------------------------
/// Handle succeeded message.
// --------------------------------------------------------------------------

- (void)requestSucceeded:(NSString *)request
{
	ECTwitterHandler* handler EC_HINT_UNUSED = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ succeeded", request, handler);
}

// --------------------------------------------------------------------------
/// Handle failed message.
// --------------------------------------------------------------------------

- (void)requestFailed:(NSString*)request withError:(NSError*)error
{
	ECTwitterHandler* handler = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ failed with error %@ %@", request, handler, error, error.userInfo);
    [self registerError:error inContext:handler];
	handler.error = error;
	[handler invokeWithStatus: StatusFailed];
	[self doneRequest: request];
}


// --------------------------------------------------------------------------
/// Handle receiving generic results.
// --------------------------------------------------------------------------

- (void)genericResultsReceived:(NSArray*)results forRequest:(NSString *)request
{
	ECDebug(TwitterChannel, @"generic results %@ for request %@", results, request);
    
	ECTwitterHandler* handler = [self handlerForRequest: request];
    for (NSObject* result in results)
    {
        [handler invokeWithResult: result];
    }
	
	[self doneRequest: request];
}

// --------------------------------------------------------------------------
// Twitter Method Calling
// --------------------------------------------------------------------------

#pragma mark -
#pragma mark Twitter Method Calling

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector
{
	[self callMethod: method httpMethod: nil parameters: parameters target: target selector: selector extra: nil];
}

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra
{
	[self callMethod: method httpMethod: nil parameters: parameters target: target selector: selector extra: extra];
}

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector
{
	[self callMethod: method httpMethod: @"POST" parameters: parameters target: target selector: selector extra: nil];
}

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra
{
	[self callMethod: method httpMethod:@"POST" parameters: parameters target: target selector: selector extra: extra];
}

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters handler:(void (^)(ECTwitterHandler* handler))handler
{
    [self callMethod:method httpMethod:nil parameters:parameters extra:nil handler:handler];
}

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters handler:(void (^)(ECTwitterHandler* handler))handler
{
    [self callMethod:method httpMethod:@"POST" parameters:parameters extra:nil handler:handler];
}

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler
{
    [self callMethod:method httpMethod:nil parameters:parameters extra:extra handler:handler];
}

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler
{
    [self callMethod:method httpMethod:@"POST" parameters:parameters extra:extra handler:handler];
}


// --------------------------------------------------------------------------
/// Call a twitter method.
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters extra:(NSObject*)extra handler:(void (^)(ECTwitterHandler* handler))handler
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine:self handler:handler];
	internalHandler.extra = extra;
    [self callMethod:method httpMethod:httpMethod parameters:parameters internalHandler:internalHandler];
    [internalHandler release];
}


// --------------------------------------------------------------------------
/// Call a twitter method.
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters target:(id) target selector:(SEL) selector extra:(NSObject*)extra
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine: self target: target selector: selector];
	internalHandler.extra = extra;
    [self callMethod:method httpMethod:httpMethod parameters:parameters internalHandler:internalHandler];
    [internalHandler release];
}

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters internalHandler:(ECTwitterHandler*)internalHandler
{
	if (parameters == nil)
	{
		parameters = [NSDictionary dictionary];
	}
	
    NSString* request = [self.engine request:method parameters:parameters method:httpMethod authentication:self.authentication];
	[self setHandler:internalHandler forRequest:request];
}

// --------------------------------------------------------------------------
/// Record/report an error.
// --------------------------------------------------------------------------

- (void)registerError:(NSError*)error inContext:(NSObject*)context
{
    NSString* es = [error description];
    NSString* us = [error.userInfo description];
    NSString* ds = [context description];
    [ECErrorReporter reportError:error message:@"%@ - %@ (in context %@)", es, us, ds];
}

@end
