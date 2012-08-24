// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 07/04/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterAuthentication.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"

#import <ECOAuthConsumer/ECOAuthConsumer.h>

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

@synthesize connection = _connection;
@synthesize engine = _engine;
@synthesize handler = _handler;
@synthesize token = _token;
@synthesize user = _user;

// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// Methods
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
/// Initialise the engine.
// --------------------------------------------------------------------------

- (id)initWithEngine:(ECTwitterEngine*)engine
{
    if ((self = [super init]) != nil)
    {
        self.engine = engine;
    }

    return self;
}

- (void)dealloc
{
    [_connection release];
    [_engine release];
    [_handler release];
    [_token release];
    [_user release];
    
    [super dealloc];
}
// --------------------------------------------------------------------------
/// Has the engine been authenticated?
// --------------------------------------------------------------------------

- (BOOL) isAuthenticated
{
	return (self.token != nil) && [self.token isValid];
}


// --------------------------------------------------------------------------
/// Authenticate.
/// We look first to see if we've got an existing token stored
/// for the user. If we have, we just use it, if not we request
/// a new one.
/// Calling with nil for the user will clear any saved token.
// --------------------------------------------------------------------------


- (void)authenticateForUser:(NSString*)user password:(NSString*)password handler:(ECTwitterHandlerBlock)handler
{
	ECTwitterHandler* newHandler = [[ECTwitterHandler alloc] initWithEngine:self.engine handler:handler];
    self.user = user;
    self.handler = newHandler;
    self.token = nil;
    [self requestXAuthAccessTokenForUsername:user password: password];
	[newHandler release];
}

- (void)requestXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password
{
	OAConsumer *consumer = [[(OAConsumer*)[OAConsumer alloc] initWithKey:self.engine.consumerKey secret:self.engine.consumerSecret] autorelease];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]
																   consumer:consumer
																	  token:nil // xAuth needs no request token?
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	
	[request setParameters:[NSArray arrayWithObjects:
							[OARequestParameter requestParameter:@"x_auth_mode" value:@"client_auth"],
							[OARequestParameter requestParameter:@"x_auth_username" value:self.user],
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
    if (self.handler)
    {
        [self.handler invokeWithResult:tokenIn];
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
        self.handler = nil;
    }
    
    [self.engine registerError:error inContext:@"authentication error"];
    self.engine.authentication = nil;
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
    [self.connection setResponse:resp];
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
        NSString* body = [[NSString alloc] initWithData:[self.connection data] encoding:NSUTF8StringEncoding];
        OAToken* newToken = [[OAToken alloc] initWithHTTPResponseBody:body];
        [self invokeHandlerForToken:newToken];
        [newToken release];
        [body release];
    }

    self.connection = nil;
}

#pragma mark - URL request

- (NSMutableURLRequest*)requestForURL:(NSURL*)url
{
    OAConsumer* consumer = [[OAConsumer alloc] initWithKey:self.engine.consumerKey secret:self.engine.consumerSecret];
    NSMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:url consumer:consumer token:self.token realm:nil signatureProvider:nil];
    [consumer autorelease];
    
    return [request autorelease];
}


@end
