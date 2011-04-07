// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 07/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterAuthentication.h"
#import "ECTwitterHandler.h"
#import "OAToken.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "MGTwitterHTTPURLConnection.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterAuthentication()

- (void)requestXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password;

@end


@implementation ECTwitterAuthentication

// --------------------------------------------------------------------------
// Log Channels
// --------------------------------------------------------------------------

ECDefineDebugChannel(AuthenticationChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(connection);
ECPropertySynthesize(consumerKey);
ECPropertySynthesize(consumerSecret);
ECPropertySynthesize(engine);
ECPropertySynthesize(handler);
ECPropertySynthesize(token);
ECPropertySynthesize(username);

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

- (id) initWithKey: (NSString*) key secret: (NSString*) secret;
{
	if ((self = [super init]) != nil)
	{
        self.consumerKey = key;
        self.consumerSecret = secret;
	}
	
	return self;
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
	
	ECTwitterHandler* handler = [[ECTwitterHandler alloc] initWithEngine:self.engine target: target selector: selector];
    self.username = user;
	if (user && savedToken && [savedToken isValid] && ([savedUser isEqualToString: user]))
	{
		self.token = savedToken;
		[handler invokeWithResult: savedToken];
	}
	else
	{
		[defaults removeObjectForKey: kSavedUserKey];
		[OAToken removeFromUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
		self.token = nil;
		
		if (user && password)
		{
			[self requestXAuthAccessTokenForUsername:user password: password];
            self.handler = handler;
			[defaults setValue: user forKey: kSavedUserKey];
		}
	}
	
	[handler release];
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
							[OARequestParameter requestParameter:@"x_auth_username" value:username],
							[OARequestParameter requestParameter:@"x_auth_password" value:password],
							nil]];		
	
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:request delegate:self];
    [request release];
    
    if (connection)
    {
        self.connection = connection;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetDataLength];
    
    // Get response code.
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    [connection setResponse:resp];
    NSInteger statusCode = [resp statusCode];
    
    if (statusCode == 304)
    {
        [connection cancel];
    }
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    [connection appendData:data];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
	self.connection = nil;
}


- (void)connectionDidFinishLoading:(MGTwitterHTTPURLConnection *)connection
{
    
    NSInteger statusCode = [[connection response] statusCode];
    NSString* body = [[NSString alloc] initWithData:[connection data] encoding:NSUTF8StringEncoding];
    
    if (statusCode >= 400) 
    {
        // TODO handle failure
        
        // Destroy the connection.
        [connection cancel];
        self.connection = nil;
        return;
    }
    else
    {
        OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:body];
        self.token = token;
        [token storeInUserDefaultsWithServiceProviderName: kProvider prefix: kPrefix];
        
        [self.handler invokeWithResult: token];
        self.handler.operation = nil;
        self.handler = nil;

        [token release];
    }

    [body release];
    self.connection = nil;
}

- (NSMutableURLRequest*) requestForURL:(NSURL*)url
{
    OAConsumer* consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.consumerSecret];
    NSMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:self.token realm:nil signatureProvider:nil];
    [consumer release];
    
    return [request autorelease];
}


@end
