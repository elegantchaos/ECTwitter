// --------------------------------------------------------------------------
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

@property (strong, nonatomic) MGTwitterEngine* engine;
@property (strong, nonatomic) NSMutableArray* errors;
@property (strong, nonatomic) NSMutableDictionary* requests;

- (void)setHandler:(ECTwitterHandler*)handler forRequest:(NSString*)request;
- (ECTwitterHandler*)handlerForRequest:(NSString*)request;
- (void)doneRequest:(NSString*)request;

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

static const BOOL xkReportErrors = NO;

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

@synthesize consumerKey = _consumerKey;
@synthesize consumerSecret = _consumerSecret;
@synthesize errors = _errors;
@synthesize engine = _engine;
@synthesize requests = _requests;

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle

// --------------------------------------------------------------------------
/// Initialise the engine.
// --------------------------------------------------------------------------

- (id)initWithConsumerKey:(NSString*)consumerKey consumerSecret:(NSString*)consumerSecret clientName:(NSString*)clientName version:(NSString*)clientVersion url:(NSURL*)clientURL;
{
	if ((self = [super init]) != nil)
	{
		MGTwitterEngine* newEngine = [[MGTwitterEngine alloc] initWithDelegate:self];
        [newEngine setClientName:clientName version:clientVersion URL:[clientURL absoluteString]];
        self.consumerKey = consumerKey;
        self.consumerSecret = consumerSecret;
		self.engine = newEngine;
        self.errors = [NSMutableArray array];
        
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
    [_consumerKey release];
    [_consumerSecret release];
	[_engine release];
	[_requests release];
    
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
	[self.requests setObject:handler forKey:request];
}

// --------------------------------------------------------------------------
/// Return the handler for a request id.
// --------------------------------------------------------------------------

- (ECTwitterHandler*)handlerForRequest:(NSString*)request
{
	return [self.requests objectForKey:request];
}

// --------------------------------------------------------------------------
/// Clear a request from our list.
// --------------------------------------------------------------------------

- (void) doneRequest:(NSString*)request
{
	ECTwitterHandler* handler = [self.requests objectForKey:request];
	handler.operation = nil;
	[self.requests removeObjectForKey:request];
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
	ECTwitterHandler* handler EC_HINT_UNUSED = [self handlerForRequest:request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ succeeded", request, handler);
}

// --------------------------------------------------------------------------
/// Handle failed message.
// --------------------------------------------------------------------------

- (void)requestFailed:(NSString*)request withError:(NSError*)error
{
	ECTwitterHandler* handler = [self handlerForRequest:request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ failed with error %@ %@", request, handler, error, error.userInfo);
    [self registerError:error inContext:handler];
	handler.error = error;
	[handler invokeWithStatus:StatusFailed];
	[self doneRequest:request];
}


// --------------------------------------------------------------------------
/// Handle receiving generic results.
// --------------------------------------------------------------------------

- (void)genericResultsReceived:(NSArray*)results forRequest:(NSString *)request
{
	ECDebug(TwitterChannel, @"generic results %@ for request %@", results, request);
    
	ECTwitterHandler* handler = [self handlerForRequest:request];
    for (NSObject* result in results)
    {
        [handler invokeWithResult:result];
    }
	
	[self doneRequest:request];
}

// --------------------------------------------------------------------------
// Twitter Method Calling
// --------------------------------------------------------------------------

#pragma mark -
#pragma mark Twitter Method Calling

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters authentication:(ECTwitterAuthentication*)authentication target:(id) target selector:(SEL) selector extra:(NSObject*)extra
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine:self target:target selector:selector];
	[self callMethod:method httpMethod:nil parameters:parameters authentication:authentication extra:extra internalHandler:internalHandler];
    [internalHandler release];
}

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters authentication:(ECTwitterAuthentication*)authentication target:(id) target selector:(SEL) selector extra:(NSObject*)extra
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine:self target:target selector:selector];
	[self callMethod:method httpMethod:@"POST" parameters:parameters authentication:authentication extra:extra internalHandler:internalHandler];
    [internalHandler release];
}

- (void) callGetMethod:(NSString*)method parameters:(NSDictionary*)parameters authentication:(ECTwitterAuthentication*)authentication extra:(NSObject*)extra handler:(ECTwitterHandlerBlock)handler
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine:self handler:handler];
    [self callMethod:method httpMethod:nil parameters:parameters authentication:authentication extra:extra internalHandler:internalHandler];
    [internalHandler release];
}

- (void) callPostMethod:(NSString*)method parameters:(NSDictionary*)parameters authentication:(ECTwitterAuthentication*)authentication extra:(NSObject*)extra handler:(ECTwitterHandlerBlock)handler
{
	ECTwitterHandler* internalHandler = [[ECTwitterHandler alloc] initWithEngine:self handler:handler];
    [self callMethod:method httpMethod:@"POST" parameters:parameters authentication:authentication extra:extra internalHandler:internalHandler];
    [internalHandler release];
}

// --------------------------------------------------------------------------
/// Call a twitter method. 
/// When it's done, the engine will call back to the specified handler.
// --------------------------------------------------------------------------

- (void) callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters authentication:(ECTwitterAuthentication*)authentication extra:(NSObject*)extra internalHandler:(ECTwitterHandler*)internalHandler
{
	internalHandler.extra = extra;

	if (parameters == nil)
	{
		parameters = [NSDictionary dictionary];
	}
	
    NSString* request = [self.engine request:method parameters:parameters method:httpMethod authentication:authentication];
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
    [self.errors addObject:error];

    ECErrorAndMessage* eam = [[ECErrorAndMessage alloc] init];
    eam.error = error;
    eam.message = [NSString stringWithFormat:@"%@ - %@ (in context %@)", es, us, ds];
    ECLog(ErrorChannel, eam);
    [eam release];
}

@end
