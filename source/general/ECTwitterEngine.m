// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterEngine.h"
#import "ECTwitterTweet.h"
#import "ECTwitterUser.h"
#import "ECTwitterPlace.h"
#import "ECTwitterHandler.h"
#import "ECTwitterAuthentication.h"
#import "MGTwitterEngine.h"

#import <ECFoundation/ECMacros.h>
#import <ECFoundation/ECErrorReporter.h>

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterEngine()

- (void)setHandler:(ECTwitterHandler*)handler forRequest:(NSString*)request;
- (ECTwitterHandler*)handlerForRequest:(NSString*)request;
- (void)doneRequest:(NSString*)request;
- (void)callMethod:(NSString*)method httpMethod:(NSString*)httpMethod parameters:(NSDictionary*)parameters target:(id)target selector:(SEL)selector extra:(NSObject*)extra;

@end

@implementation ECTwitterEngine


// --------------------------------------------------------------------------
// Debug Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(TwitterChannel);
ECDefineLogChannel(ErrorChannel);

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(authentication);
ECPropertySynthesize(engine);
ECPropertySynthesize(requests);

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle

// --------------------------------------------------------------------------
//! Initialise the engine.
// --------------------------------------------------------------------------

- (id) initWithAuthetication:(ECTwitterAuthentication *)authentication
{
	if ((self = [super init]) != nil)
	{
		MGTwitterEngine* engine = [[MGTwitterEngine alloc] initWithDelegate:self];
        self.authentication = authentication;
        authentication.engine = self;
		self.engine = engine;
        
		[engine release];
        
		self.requests = [NSMutableDictionary dictionary];

		ECDebug(TwitterChannel, @"initialised engine");
	}
	
	return self;
}


// --------------------------------------------------------------------------
//! Clean up and release references.
// --------------------------------------------------------------------------

- (void) dealloc 
{
	ECPropertyDealloc(engine);
	ECPropertyDealloc(requests);
    
    [super dealloc];
}



// ==============================================
// Request Handling
// ==============================================

#pragma mark -
#pragma mark Request Handling

// --------------------------------------------------------------------------
//! Remember a request id and associate it with a handler.
// --------------------------------------------------------------------------

- (void) setHandler: (ECTwitterHandler*) handler forRequest: (NSString*) request
{
	[self.requests setObject: handler forKey: request];
}

// --------------------------------------------------------------------------
//! Return the handler for a request id.
// --------------------------------------------------------------------------

- (ECTwitterHandler*) handlerForRequest: (NSString*) request
{
	return [self.requests objectForKey: request];
}

// --------------------------------------------------------------------------
//! Clear a request from our list.
// --------------------------------------------------------------------------

- (void) doneRequest: (NSString*) request
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
//! Handle succeeded message.
// --------------------------------------------------------------------------

- (void)requestSucceeded:(NSString *)request
{
	ECTwitterHandler* handler EC_HINT_UNUSED = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ succeeded", request, handler);
}

// --------------------------------------------------------------------------
//! Handle failed message.
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
//! Handle receiving generic results.
// --------------------------------------------------------------------------

- (void)genericResultsReceived:(NSArray*)results forRequest:(NSString *)request;
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
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
{
	[self callMethod: method httpMethod: nil parameters: parameters target: target selector: selector extra: nil];
}

// --------------------------------------------------------------------------
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callGetMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;
{
	[self callMethod: method httpMethod: nil parameters: parameters target: target selector: selector extra: extra];
}

// --------------------------------------------------------------------------
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
{
	[self callMethod: method httpMethod: @"POST" parameters: parameters target: target selector: selector extra: nil];
}

// --------------------------------------------------------------------------
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callPostMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;
{
	[self callMethod: method httpMethod: @"POST" parameters: parameters target: target selector: selector extra: extra];
}

// --------------------------------------------------------------------------
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callMethod: (NSString*) method httpMethod: (NSString*) httpMethod parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;
{
	if (parameters == nil)
	{
		parameters = [NSDictionary dictionary];
	}
	
    NSString* request = [self.engine request:method parameters:parameters method:httpMethod];
	ECTwitterHandler* handler = [[ECTwitterHandler alloc] initWithEngine: self target: target selector: selector];
	handler.extra = extra;
	[self setHandler: handler forRequest:request];
    [handler release];
}

// --------------------------------------------------------------------------
//! Record/report an error.
// --------------------------------------------------------------------------

- (void)registerError:(NSError*)error inContext:(NSObject*)context
{
    NSString* es = [error description];
    NSString* us = [error.userInfo description];
    NSString* ds = [context description];
    [ECErrorReporter reportError:error message:@"%@ - %@ (in context %@)", es, us, ds];
}

@end
