// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 13/09/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterEngine.h"
#import "ECTwitterTweet.h"
#import "ECTwitterUser.h"
#import "ECTwitterPlace.h"
#import "ECTwitterHandler.h"

#import "MGTwitterParserFactoryYAJLGeneric.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterEngine()

- (void) setHandler: (ECTwitterHandler*) handler forRequest: (NSString*) request;
- (ECTwitterHandler*) handlerForRequest: (NSString*) request;
- (void) doneRequest: (NSString*) request;
- (void) callMethod: (NSString*) method httpMethod: (NSString*) httpMethod parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector extra: (NSObject*) extra;

@end

@implementation ECTwitterEngine


// --------------------------------------------------------------------------
// Debug Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(TwitterChannel);
ECDefineDebugChannel(MGTwitterEngineChannel);

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

NSString *const kSavedUserKey = @"ECTwitterEngineUser";
NSString *const kProvider = @"ECTwitterEngine";
NSString *const kPrefix = @"";

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(engine);
ECPropertySynthesize(requests);
ECPropertySynthesize(token);

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Lifecycle

// --------------------------------------------------------------------------
//! Initialise the engine.
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;
{
	if ((self = [super init]) != nil)
	{
		MGTwitterParserFactory* parser = [[MGTwitterParserFactoryYAJLGeneric alloc] init];
		MGTwitterEngine* engine = [[MGTwitterEngine alloc] initWithDelegate:self parser: parser];
		
		[engine setConsumerKey: key secret: secret];
		self.engine = engine;

		[engine release];
		[parser release];

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
	ECPropertyDealloc(token);
	
    [super dealloc];
}

// ==============================================
// Authentication
// ==============================================

#pragma mark -
#pragma mark Authentication

// --------------------------------------------------------------------------
//! Authenticate.
//! Look to see if we've got an existing token stored
//! for the user. If we have, we use it and return YES, 
//! if not we return NO.
// --------------------------------------------------------------------------

- (BOOL) authenticateForUser: (NSString*) user
{
	ECDebug(TwitterChannel, @"checking saved authentication for %@", user);
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* savedUser = [defaults stringForKey: kSavedUserKey];
	OAToken* savedToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: kProvider prefix: kPrefix];
	
	BOOL result = (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]));
	if (result)
	{
		[self.engine setUsername: user];
		[self.engine setAccessToken: savedToken];
		self.token = savedToken;
	}

	[savedToken release];
	
	return result;
}

// --------------------------------------------------------------------------
//! Authenticate.
//! We look first to see if we've got an existing token stored
//! for the user. If we have, we just use it, if not we request
//! a new one.
//! Calling with nil for the user will clear any saved token.
// --------------------------------------------------------------------------

- (void) authenticateForUser: (NSString*) user password: (NSString*) password target: (id) target selector: (SEL) selector
{
	ECDebug(TwitterChannel, @"requesting authentication for %@ password %@", user, password);

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* savedUser = [defaults stringForKey: kSavedUserKey];
	OAToken* savedToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: kProvider prefix: kPrefix];
	
	ECTwitterHandler* handler = [[ECTwitterHandler alloc] initWithEngine: self target: target selector: selector];

	if (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]))
	{
		[self.engine setAccessToken: savedToken];
		self.token = savedToken;
		[handler invokeWithResults: savedToken];
	}
	else
	{
		self.token = nil;
		[defaults removeObjectForKey: kSavedUserKey];
		[OAToken removeFromUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
		[self.engine setAccessToken: nil];
		
		if (user && password)
		{
			NSString* request = [self.engine getXAuthAccessTokenForUsername:user password: password];
			[self setHandler: handler forRequest: request];
			[defaults setValue: user forKey: kSavedUserKey];
		}
	}
	
	[handler release];
	[savedToken release];
}

// --------------------------------------------------------------------------
//! Has the engine been authenticated?
// --------------------------------------------------------------------------

- (BOOL) isAuthenticated
{
	return (self.token != nil) && [self.token isValid];
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

- (void) requestSucceeded: (NSString *) request
{
	ECTwitterHandler* handler EC_HINT_UNUSED = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ succeeded", request, handler);
}

// --------------------------------------------------------------------------
//! Handle failed message.
// --------------------------------------------------------------------------

- (void) requestFailed: (NSString*) request withError: (NSError*) error
{
	ECTwitterHandler* handler = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ failed with error %@ %@", request, handler, error, error.userInfo);
	handler.error = error;
	[handler invokeWithStatus: StatusFailed];
	[self doneRequest: request];
}


// --------------------------------------------------------------------------
//! Handle receiving an authorisation token.
// --------------------------------------------------------------------------

- (void) accessTokenReceived: (OAToken*) token forRequest: (NSString*) request
{
	ECDebug(TwitterChannel, @"authenticated ok");

	MGTwitterEngine* engine = self.engine;
    self.token = token;
    [engine setAccessToken:token];
	[token storeInUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
	
	ECTwitterHandler* handler = [self handlerForRequest: request];
	[handler invokeWithResults: token];
	[self doneRequest: request];
}


// --------------------------------------------------------------------------
//! Handle receiving geo results.
// --------------------------------------------------------------------------

- (void) genericResultsReceived:(NSArray*) results forRequest:(NSString *) request;
{
	ECDebug(TwitterChannel, @"generic results %@ for request %@", results, request);

	ECTwitterHandler* handler = [self handlerForRequest: request];
	[handler invokeWithResults: results];
	
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
	
    NSString* request = [self.engine genericRequestWithMethod: httpMethod path: method queryParameters: parameters body: nil];
	ECTwitterHandler* handler = [[ECTwitterHandler alloc] initWithEngine: self target: target selector: selector];
	handler.extra = extra;
	[self setHandler: handler forRequest:request];
}

@end
