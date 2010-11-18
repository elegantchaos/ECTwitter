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
	[handler invokeWithStatus: StatusFailed];
	[self doneRequest: request];
}

// --------------------------------------------------------------------------
//! Handle receiving a list of status updates.
//! We convert the dictionaries into a list of ECTwitterTweet
//! objects, then call on to the registered handler for the request.
// --------------------------------------------------------------------------

- (void) statusesReceived:(NSArray *)statuses forRequest: (NSString*) request
{
	ECDebug(TwitterChannel, @"received %d tweets for request %@", [statuses count], request);
#if 0
	ECTwitterHandler* handler = [self handlerForRequest: request];	
	if ([handler respondsToSelector: @selector(twitterEngine:didReceiveTweets:)])
	{
		NSMutableArray* tweets = [[NSMutableArray alloc] init];
		for (NSMutableDictionary* status in statuses)
		{
			ECTwitterTweet* tweet = [(ECTwitterTweet*) [ECTwitterTweet alloc] initWithDictionary: status];
			ECDebug(TwitterChannel, @"tweet %@", tweet);
			[tweets addObject: tweet];
			[tweet release];
		}
		
		[handler twitterEngine: self didReceiveTweets: tweets];
		[tweets release];
	}
#endif

	[self doneRequest: request];
}

// --------------------------------------------------------------------------
// --------------------------------------------------------------------------

- (void) directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier
{
	ECDebug(TwitterChannel, @"directMessagesReceived %@ %@", messages, identifier);
	
}

// --------------------------------------------------------------------------
//! Handle receiving a list of user information.
//! We convert the dictionaries into a list of ECTwitterUser
//! objects, then call on to the registered handler for the request.
// --------------------------------------------------------------------------

- (void) userInfoReceived: (NSArray*) userInfos forRequest: (NSString*) request
{
	ECDebug(TwitterChannel, @"received %d users for request %@\n%@", [userInfos count], request, userInfos);

#if 0
	ECTwitterHandler* handler = [self handlerForRequest: request];
	if ([handler respondsToSelector: @selector(twitterEngine:didReceiveUsers:)])
	{
		NSMutableArray* users = [[NSMutableArray alloc] init];
		for (NSMutableDictionary* info in userInfos)
		{
			ECTwitterUser* user = [[ECTwitterUser alloc] initWithUserInfo: info];
			ECDebug(TwitterChannel, @"user %@", user);
			[users addObject: user];
			[user release];
		}
		
		[handler twitterEngine: self didReceiveUsers: users];
		[users release];
	}
#endif
	
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
//! Handle receiving a list of user ids.
// --------------------------------------------------------------------------

- (void) socialGraphInfoReceived: (NSArray*) socialGraphInfo forRequest: (NSString*) request
{
#if 0
	NSDictionary* info = [socialGraphInfo objectAtIndex: 0];
	
	NSArray* ids = [info objectForKey: @"ids"];
	MGTwitterEngineCursorID next = [[info objectForKey: @"next"] intValue];
	MGTwitterEngineCursorID previous = [[info objectForKey: @"previous"] intValue];
	
	ECDebug(TwitterChannel, @"received %d user ids for request %@", [ids count], request);
	
	ECTwitterHandler* handler = [self handlerForRequest: request];
	if ([handler respondsToSelector: @selector(twitterEngine:didReceiveUserIds:nextCursor:previousCursor:)])
	{
		[handler twitterEngine: self didReceiveUserIds: ids nextCursor: next previousCursor: previous];
	}
#endif
	
	[self doneRequest: request];
}

// --------------------------------------------------------------------------
//! Handle receiving geo results.
// --------------------------------------------------------------------------

- (void) genericResultsReceived:(NSArray*) dataArray forRequest:(NSString *) request;
{
	ECDebug(TwitterChannel, @"generic results %@ for request %@", dataArray, request);

	NSDictionary* dataDictionary = (NSDictionary*) dataArray;
//	NSDictionary* query = [results objectForKey: @"query"];
	NSDictionary* results = [dataDictionary objectForKey: @"result"];
	
	ECTwitterHandler* handler = [self handlerForRequest: request];
	[handler invokeWithResults: results];
}

// --------------------------------------------------------------------------
//! Call a twitter method. 
//! When it's done, the engine will call back to the specified target/selector.
// --------------------------------------------------------------------------

- (void) callMethod: (NSString*) method parameters: (NSDictionary*) parameters target: (id) target selector: (SEL) selector;
{
    NSString* request = [self.engine genericRequestWithMethod: nil path: method queryParameters: parameters body: nil];
	ECTwitterHandler* handler = [[ECTwitterHandler alloc] initWithEngine: self target: target selector: selector];
	[self setHandler: handler forRequest:request];
}

#if 0
// --------------------------------------------------------------------------
//! Perform a geo lookup using a given location.
// --------------------------------------------------------------------------

- (void) getGeoSearchAt: (CLLocation*) location handler: (ECTwitterHandler*) handler
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	
	CLLocationCoordinate2D coords = location.coordinate;
	[params setObject:[NSString stringWithFormat: @"%lf", coords.latitude] forKey:@"lat"];
	[params setObject:[NSString stringWithFormat: @"%lf", coords.longitude] forKey:@"long"];
	[params setObject: @"poi" forKey: @"granularity"];
	[params setObject: @"max_results" forKey: [NSNumber numberWithInt: 20]];
	 
    NSString* request = [self.engine genericRequestWithMethod: nil path: @"geo/search" queryParameters: params body: nil];
	[self setHandler: handler forRequest:request];
}

#endif

@end
