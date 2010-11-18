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

#import "MGTwitterParserFactoryTouchJSON.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterEngine()

- (id<ECTwitterEngineHandler>) handlerForRequest: (NSString*) request;
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
		MGTwitterParserFactory* parser = [[MGTwitterParserFactoryTouchJSON alloc] init];
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

- (void) authenticateForUser: (NSString*) user password: (NSString*) password handler: (NSObject<ECTwitterEngineHandler>*) handler
{
	ECDebug(TwitterChannel, @"requesting authentication for %@ password %@", user, password);

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* savedUser = [defaults stringForKey: kSavedUserKey];
	OAToken* savedToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: kProvider prefix: kPrefix];
	
	if (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]))
	{
		[self.engine setAccessToken: savedToken];
		self.token = savedToken;
		if ([handler respondsToSelector: @selector(twitterEngine:didAuthenticateWithToken:)])
		{
			[handler twitterEngine: self didAuthenticateWithToken: savedToken];
		}
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

- (void) setHandler: (NSObject<ECTwitterEngineHandler>*) handler forRequest: (NSString*) request
{
	[self.requests setObject: handler forKey: request];
}

// --------------------------------------------------------------------------
//! Return the handler for a request id.
// --------------------------------------------------------------------------

- (NSObject<ECTwitterEngineHandler>*) handlerForRequest: (NSString*) request
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
	NSObject<ECTwitterEngineHandler>* handler EC_HINT_UNUSED = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ succeeded", request, handler);
}

// --------------------------------------------------------------------------
//! Handle failed message.
// --------------------------------------------------------------------------

- (void) requestFailed: (NSString*) request withError: (NSError*) error
{
	NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];
	ECAssertNonNil(handler);
	
	ECDebug(TwitterChannel, @"request %@ for handler %@ failed with error %@ %@", request, handler, error, error.userInfo);
	if ([handler respondsToSelector: @selector(twitterEngine:failedWithError:)])
	{
		[handler twitterEngine: self failedWithError: error];
	}
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
	NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];	
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

	NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];
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
	
	NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];
	if ([handler respondsToSelector: @selector(twitterEngine:didAuthenticateWithToken:)])
	{
		[handler twitterEngine: self didAuthenticateWithToken: token];
	}
	
	[self doneRequest: request];
	
}

// --------------------------------------------------------------------------
//! Handle receiving a list of user ids.
// --------------------------------------------------------------------------

- (void) socialGraphInfoReceived: (NSArray*) socialGraphInfo forRequest: (NSString*) request
{
	NSDictionary* info = [socialGraphInfo objectAtIndex: 0];
	
	NSArray* ids = [info objectForKey: @"ids"];
	MGTwitterEngineCursorID next = [[info objectForKey: @"next"] intValue];
	MGTwitterEngineCursorID previous = [[info objectForKey: @"previous"] intValue];
	
	ECDebug(TwitterChannel, @"received %d user ids for request %@", [ids count], request);
	
	NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];
	if ([handler respondsToSelector: @selector(twitterEngine:didReceiveUserIds:nextCursor:previousCursor:)])
	{
		[handler twitterEngine: self didReceiveUserIds: ids nextCursor: next previousCursor: previous];
	}

	[self doneRequest: request];
}

// --------------------------------------------------------------------------
//! Handle receiving geo results.
// --------------------------------------------------------------------------

- (void) genericResultsReceived:(NSArray*) genericResults forRequest:(NSString *) request;
{
	ECDebug(TwitterChannel, @"generic results %@ for request %@", genericResults, request);

	NSDictionary* results = (NSDictionary*) genericResults;
	NSDictionary* query = [results objectForKey: @"query"];
	NSDictionary* result = [results objectForKey: @"result"];
	
	NSArray* placesInfo = [result objectForKey: @"places"];
	if (placesInfo)
	{
		NSMutableArray* places = [[NSMutableArray alloc] init];
		for (NSDictionary* placeInfo in placesInfo)
		{
			ECTwitterPlace* place = [[ECTwitterPlace alloc] initWithPlaceInfo: placeInfo];
			[places addObject: place];
			[place release];
		}
		
		NSObject<ECTwitterEngineHandler>* handler = [self handlerForRequest: request];
		if ([handler respondsToSelector: @selector(twitterEngine:didReceiveGeoResults:forQuery:)])
		{
			[handler twitterEngine: self didReceiveGeoResults: places forQuery: query];
		}
		[places release];
	}
}

// --------------------------------------------------------------------------
//! Perform a geo lookup using a given location.
// --------------------------------------------------------------------------

- (void) getGeoSearchAt: (CLLocation*) location handler: (NSObject<ECTwitterEngineHandler>*) handler
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

@end
