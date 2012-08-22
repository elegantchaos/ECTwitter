// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 07/04/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterAuthentication.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"
#import "OAToken.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "ECTwitterConnection.h"
#import "MGTwitterEngine.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterAuthentication()

- (void)requestXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password;
- (void)invokeHandlerForToken:(OAToken*)token;
- (void)invokeHandlerForError;
@end


@implementation ECTwitterAuthentication

// --------------------------------------------------------------------------
// Log Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(AuthenticationChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

@synthesize connection;
@synthesize consumerKey;
@synthesize consumerSecret;
@synthesize engine;
@synthesize handler;
@synthesize token;
@synthesize username;

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

NSString *const kSavedUserKey = @"ECTwitterEngineUser";
NSString *const kProvider = @"ECTwitterEngine";
NSString *const kPrefix = @"";

// --------------------------------------------------------------------------
// Methods
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
//! Initialise the engine.
// --------------------------------------------------------------------------

- (id) initWithKey: (NSString*) key secret: (NSString*) secret
{
	if ((self = [super init]) != nil)
	{
        self.consumerKey = key;
        self.consumerSecret = secret;
	}
	
	return self;
}

- (void)dealloc 
{
    [connection dealloc];
    [consumerKey dealloc];
    [consumerSecret dealloc];
    [engine dealloc];
    [handler dealloc];
    [token dealloc];
    [username dealloc];
    
    [super dealloc];
}
// --------------------------------------------------------------------------
//! Has the engine been authenticated?
// --------------------------------------------------------------------------

- (BOOL) isAuthenticated
{
	return (self.token != nil) && [self.token isValid];
}

// --------------------------------------------------------------------------
//! Authenticate.
//! Look to see if we've got an existing token stored
//! for the user. If we have, we use it and return YES, 
//! if not we return NO.
// --------------------------------------------------------------------------

- (BOOL) authenticateForUser: (NSString*) user
{
	ECDebug(AuthenticationChannel, @"checking saved authentication for %@", user);
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* savedUser = [defaults stringForKey: kSavedUserKey];
	OAToken* savedToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: kProvider prefix: kPrefix];
	
	BOOL result = (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]));
	if (result)
	{
		self.username = user;
		self.token = savedToken;
        self.engine.engine.authentication = self;
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
	ECDebug(AuthenticationChannel, @"requesting authentication for %@ password %@", user, password);
    
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSString* savedUser = [defaults stringForKey: kSavedUserKey];
	OAToken* savedToken = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName: kProvider prefix: kPrefix];
	
	ECTwitterHandler* newHandler = [[ECTwitterHandler alloc] initWithEngine:self.engine target: target selector: selector];
    self.username = user;
	if (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]))
	{
        [self invokeHandlerForToken:savedToken];
	}
	else
	{
		[defaults removeObjectForKey: kSavedUserKey];
		[OAToken removeFromUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
		self.token = nil;
		
		if (user && password)
		{
            self.handler = newHandler;
			[defaults setValue: user forKey: kSavedUserKey];
			[self requestXAuthAccessTokenForUsername:user password: password];
		}
	}
	
	[newHandler release];
	[savedToken release];
}

- (void)requestXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password
{
	OAConsumer *consumer = [[(OAConsumer*) [OAConsumer alloc] initWithKey:[self consumerKey] secret:[self consumerSecret]] autorelease];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]
																   consumer:consumer
																	  token:nil // xAuth needs no request token?
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	
	[request setParameters:[NSArray arrayWithObjects:
							[OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
							[OARequestParameter requestParameter:@"x_auth_username" value:self.username],
							[OARequestParameter requestParameter:@"x_auth_password" value:password],
							nil]];		
	
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    ECTwitterConnection* newConnection = [[ECTwitterConnection alloc] initWithRequest:request delegate:self];
    [request release];
    
    if (newConnection)
    {
        self.connection = newConnection;
        [newConnection release];
    }
}

#pragma mark - Handler routines

- (void)invokeHandlerForToken:(OAToken*)tokenIn
{
    self.token = tokenIn;
    [token storeInUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
    self.engine.engine.authentication = self;

    if (self.handler)
    {
        [self.handler invokeWithResult:tokenIn];
        self.handler.operation = nil;
        self.handler = nil;
    }

    self.connection = nil;
}

- (void)invokeHandlerForError
{
    ECTwitterConnection* c = self.connection;
    NSError* error = nil;
    
    if (c)
    {
        NSInteger statusCode = [[c response] statusCode];
        NSMutableDictionary* info = [NSMutableDictionary dictionaryWithObjectsAndKeys: [c response], @"response", nil];
        NSData* data = [c data];
        if (data)
        {
            NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [info setObject:body forKey:@"body"];
            [body release];
        }
        error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:info];
        [c cancel];
        self.connection = nil;
    }

    ECTwitterHandler* h = self.handler;
    if (h)
    {
        h.error = error;
        [h invokeWithStatus:StatusFailed];
        h.operation = nil;
        self.handler = nil;
    }
    
    [self.engine registerError:error inContext:@"authentication error"];
    self.engine.engine.authentication = nil;
}

#pragma mark - Connection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	ECDebug(AuthenticationChannel, @"received authentication challenge");
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(ECTwitterConnection*)connectionIn didReceiveResponse:(NSURLResponse *)response
{
	ECDebug(AuthenticationChannel, @"received response");

    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connectionIn resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    [connection setResponse:resp];
    NSInteger statusCode = [resp statusCode];
    
    if (statusCode == 304)
    {
        [self invokeHandlerForError];
    }
}


- (void)connection:(ECTwitterConnection*)connectionIn didReceiveData:(NSData *)data
{
	ECDebug(AuthenticationChannel, @"received data");

    [connectionIn appendData:data];
}


- (void)connection:(ECTwitterConnection*)connection didFailWithError:(NSError *)error
{
	ECDebug(AuthenticationChannel, @"failed with error");
    [self invokeHandlerForError];
}


- (void)connectionDidFinishLoading:(ECTwitterConnection*)connectionIn
{
	ECDebug(AuthenticationChannel, @"finished loading");
    
    NSInteger statusCode = [[connectionIn response] statusCode];
    if (statusCode >= 400) 
    {
        [self invokeHandlerForError];
    }
    else
    {
        NSString* body = [[NSString alloc] initWithData:[connection data] encoding:NSUTF8StringEncoding];
        OAToken* newToken = [[OAToken alloc] initWithHTTPResponseBody:body];
        [self invokeHandlerForToken:newToken];
        [newToken release];
        [body release];
    }

    self.connection = nil;
}

#pragma mark - URL request

- (NSMutableURLRequest*) requestForURL:(NSURL*)url
{
    OAConsumer* consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.consumerSecret];
    NSMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:self.token realm:nil signatureProvider:nil];
    [consumer autorelease];
    
    return [request autorelease];
}


@end
