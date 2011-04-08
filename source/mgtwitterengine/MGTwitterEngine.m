// --------------------------------------------------------------------------
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Heavily modified by Sam Deane.
//  Copyright 2008 Instinctive Code.
// --------------------------------------------------------------------------

#import "MGTwitterEngine.h"
#import "ECTwitterConnection.h"
#import "ECTwitterParser.h"
#import "ECTwitterAuthentication.h"

#import <ECFoundation/NSDictionary+ECUtilities.h>


#pragma mark - Private Interface

@interface MGTwitterEngine()

ECPropertyRetained(clientName, NSString*);
ECPropertyRetained(clientVersion, NSString*);
ECPropertyRetained(clientURL, NSString*);

- (NSString*)queryStringWithBase:(NSString*)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSString*)encodeString:(NSString*)string;
- (NSString*)sendRequest:(NSURLRequest *)theRequest;
- (NSMutableURLRequest *)requestWithMethod:(NSString*)method path:(NSString*)path parameters:(NSDictionary *)params;
- (void)parseDataFromConnection:(ECTwitterConnection*)connection;
- (BOOL) isValidDelegateForSelector:(SEL)selector;

@end

#pragma mark - Implementation

@implementation MGTwitterEngine

#pragma mark - Properties

ECPropertySynthesize(authentication);
ECPropertySynthesize(clientName);
ECPropertySynthesize(clientVersion);
ECPropertySynthesize(clientURL);
ECPropertySynthesize(secure);
ECPropertySynthesize(apiDomain);
ECPropertySynthesize(searchDomain);

#pragma mark - Debug Channels

ECDefineDebugChannel(MGTwitterEngineChannel);

#pragma mark - Constants

static NSString *const kAPIFormat              = @"json";
static NSString *const kTwitterDomain          = @"api.twitter.com/1";
static NSString *const kSearchDomain           = @"search.twitter.com";
static NSString *const kPostMethod             = @"POST";

static const NSTimeInterval kRequestTimeout = 25.0; // Twitter usually fails quickly if it's going to fail at all.


#pragma mark - Lifecycle

// --------------------------------------------------------------------------
//! Construct engine.
// --------------------------------------------------------------------------

- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate
{
    if ((self = [super init])) {
        mDelegate = newDelegate; // deliberately weak reference
        mConnections = [[NSMutableDictionary alloc] initWithCapacity:0];
        self.clientName = @"ECTwitter";
        self.clientVersion = @"1.0";
        self.clientURL = @"http://www.elegantchaos.com/libraries/ectwitter";
        self.apiDomain = kTwitterDomain;
        self.searchDomain = kSearchDomain;
        
        self.secure = YES;

    }
    
    return self;
}

// --------------------------------------------------------------------------
//! Cleanup.
// --------------------------------------------------------------------------

- (void)dealloc
{
    mDelegate = nil;
 
    ECPropertyDealloc(authentication);
    ECPropertyDealloc(apiDomain);
    ECPropertyDealloc(clientName);
    ECPropertyDealloc(clientVersion);
    ECPropertyDealloc(clientURL);
    ECPropertyDealloc(searchDomain);
    
    [[mConnections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [mConnections release];
	
    [super dealloc];
}


#pragma mark Configuration and Accessors

// --------------------------------------------------------------------------
//! Set up client details for reporting to twitter.
// --------------------------------------------------------------------------

- (void)setClientName:(NSString*)name version:(NSString*)version URL:(NSString*)url;
{
    self.clientName = name;
    self.clientVersion = version;
    self.clientURL = url;
}

#pragma mark Connection methods

// --------------------------------------------------------------------------
//! Return number of active connections.
// --------------------------------------------------------------------------

- (NSUInteger)numberOfConnections
{
    return [mConnections count];
}

// --------------------------------------------------------------------------
//! Return array of identifiers for active connections.
// --------------------------------------------------------------------------

- (NSArray *)connectionIdentifiers
{
    return [mConnections allKeys];
}

// --------------------------------------------------------------------------
//! Close connection with a given identifier.
// --------------------------------------------------------------------------

- (void)closeConnection:(NSString*)connectionIdentifier
{
    ECTwitterConnection* connection = [mConnections objectForKey:connectionIdentifier];
    if (connection) {
        [connection cancel];
        [mConnections removeObjectForKey:connectionIdentifier];
		if ([self isValidDelegateForSelector:@selector(connectionFinished:)])
			[mDelegate connectionFinished:connectionIdentifier];
    }
}

// --------------------------------------------------------------------------
//! Close all connections.
// --------------------------------------------------------------------------

- (void)closeAllConnections
{
    [[mConnections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [mConnections removeAllObjects];
}


#pragma mark Utility methods

// --------------------------------------------------------------------------
//! Build query string.
// --------------------------------------------------------------------------

- (NSString*)queryStringWithBase:(NSString*)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
    if (params) {
        NSUInteger i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
             name, [self encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}

// --------------------------------------------------------------------------
//! Encode string.
// --------------------------------------------------------------------------

- (NSString*)encodeString:(NSString*)string
{
    NSString *result = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                 (CFStringRef)string, 
                                                                 NULL, 
                                                                 (CFStringRef)@";/?:@&=$+{}<>,",
                                                                 kCFStringEncodingUTF8);
    return [result autorelease];
}

#pragma mark Request sending methods

// --------------------------------------------------------------------------
//! Send request.
// --------------------------------------------------------------------------

-(NSString*)sendRequest:(NSURLRequest *)theRequest;
{
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    ECTwitterConnection* connection = [[ECTwitterConnection alloc] initWithRequest:theRequest delegate:self ];
    
    if (!connection) {
        return nil;
    } else {
        [mConnections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self isValidDelegateForSelector:@selector(connectionStarted:)])
		[mDelegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}


#pragma mark Request 

// --------------------------------------------------------------------------
//! Make a request.
// --------------------------------------------------------------------------

- (NSString*) request:(NSString*)twitterPath parameters:(NSDictionary *)params method:(NSString*)method;
{
	NSString* path = [NSString stringWithFormat:@"%@.%@", twitterPath, kAPIFormat];
    NSMutableURLRequest* request = [self requestWithMethod:method path:path parameters:params];
    
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:kPostMethod]);
    if (isPOST) 
    {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
		NSString* body = [self queryStringWithBase:nil parameters:params prefixed:NO];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    }
	
	return [self sendRequest:request];
}

// --------------------------------------------------------------------------
//! Make a request.
// --------------------------------------------------------------------------

- (NSMutableURLRequest *)requestWithMethod:(NSString*)method path:(NSString*)path parameters:(NSDictionary *)params 
{
	NSString *contentType = [params objectForKey:@"Content-Type"];
	if(contentType)
    {
		params = [params dictionaryWithoutKey:@"Content-Type"];
	}
    else
    {
		contentType = @"application/x-www-form-urlencoded";
	}
	
    // Construct appropriate URL string.
    NSString *fullPath = [path stringByAddingPercentEscapesUsingEncoding:NSNonLossyASCIIStringEncoding];
    if (params && ![method isEqualToString:kPostMethod]) {
        fullPath = [self queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
    
	BOOL isSearch = NO; // (requestType == MGTwitterSearchRequest || requestType == MGTwitterSearchCurrentTrendsRequest);
	NSString* domain = isSearch ? self.searchDomain : self.apiDomain;
	NSString* connectionType = (self.secure && !isSearch) ? @"https" : @"http";
		
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
                           connectionType,
                           domain, fullPath];
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
    
	ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: finalURL = %@", finalURL);

    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
	NSMutableURLRequest *theRequest = nil;
    if(self.authentication)
    {
        theRequest = [self.authentication requestForURL:finalURL];
		[theRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData ];
		[theRequest setTimeoutInterval:kRequestTimeout];
	}
    else
    {
		theRequest = [NSMutableURLRequest requestWithURL:finalURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
	}
    if (method) {
        [theRequest setHTTPMethod:method];
    }
    
    [theRequest setHTTPShouldHandleCookies:NO];
    
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:self.clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:self.clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:self.clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
	
    [theRequest setValue:contentType    forHTTPHeaderField:@"Content-Type"];
    	
    return theRequest;
}

#pragma mark Parsing methods

// --------------------------------------------------------------------------
//! Parse received data.
// --------------------------------------------------------------------------

- (void)parseDataFromConnection:(ECTwitterConnection*)connection
{
    NSData* data = [[connection data] copy];
    NSString* identifier = [[connection identifier] copy];

	ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: jsonData = %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);

    ECTwitterParser* parser = [[ECTwitterParser alloc] initWithDelegate:mDelegate options:MGTwitterEngineDeliveryAllResultsOption];
    [parser parseData:data identifier:identifier];
    [parser release];

    [data release];
    [identifier release];
}

#pragma mark Delegate methods

// --------------------------------------------------------------------------
//! Does delegate support a method?
// --------------------------------------------------------------------------

- (BOOL) isValidDelegateForSelector:(SEL)selector
{
	return ((mDelegate != nil) && [mDelegate respondsToSelector:selector]);
}


#pragma mark NSURLConnection delegate methods

// --------------------------------------------------------------------------
//! Respond to challenge.
// --------------------------------------------------------------------------

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

// --------------------------------------------------------------------------
//! Process response.
// --------------------------------------------------------------------------

- (void)connection:(ECTwitterConnection*)connection didReceiveResponse:(NSURLResponse *)response
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
        // Not modified, or generic success.
		if ([self isValidDelegateForSelector:@selector(requestSucceeded:)])
			[mDelegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) 
        {
        }
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[mConnections removeObjectForKey:connectionIdentifier];
		if ([self isValidDelegateForSelector:@selector(connectionFinished:)])
			[mDelegate connectionFinished:connectionIdentifier];
    }
    
        ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: (%ld) [%@]:\r%@", 
              (long)[resp statusCode], 
              [NSHTTPURLResponse localizedStringForStatusCode:[((NSHTTPURLResponse *)response) statusCode]], 
              [((NSHTTPURLResponse *)response) allHeaderFields]);
}

// --------------------------------------------------------------------------
//! Process data.
// --------------------------------------------------------------------------

- (void)connection:(ECTwitterConnection*)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}

// --------------------------------------------------------------------------
//! Process failure.
// --------------------------------------------------------------------------

- (void)connection:(ECTwitterConnection*)connection didFailWithError:(NSError *)error
{
	NSString *connectionIdentifier = [connection identifier];
	
    // Inform delegate.
	if ([self isValidDelegateForSelector:@selector(requestFailed:withError:)]){
		[mDelegate requestFailed:connectionIdentifier
					   withError:error];
	}
    
    // Release the connection.
    [mConnections removeObjectForKey:connectionIdentifier];
	if ([self isValidDelegateForSelector:@selector(connectionFinished:)])
		[mDelegate connectionFinished:connectionIdentifier];
}

// --------------------------------------------------------------------------
//! Process successful completion.
// --------------------------------------------------------------------------

- (void)connectionDidFinishLoading:(ECTwitterConnection*)connection
{

    NSInteger statusCode = [[connection response] statusCode];

    if (statusCode >= 400) {
        // Assume failure, and report to delegate.
        NSData *receivedData = [connection data];
        NSString *body = [receivedData length] ? [NSString stringWithUTF8String:[receivedData bytes]] : @"";

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [connection response], @"response",
                                  body, @"body",
                                  nil];
        NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:userInfo];
		if ([self isValidDelegateForSelector:@selector(requestFailed:withError:)])
			[mDelegate requestFailed:[connection identifier] withError:error];

        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[mConnections removeObjectForKey:connectionIdentifier];
		if ([self isValidDelegateForSelector:@selector(connectionFinished:)])
			[mDelegate connectionFinished:connectionIdentifier];
        return;
    }

	NSString *connID = nil;
	connID = [connection identifier];
	
    // Inform delegate.
	if ([self isValidDelegateForSelector:@selector(requestSucceeded:)])
		[mDelegate requestSucceeded:connID];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
		// Dump data as string for debugging.
		ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: Succeeded! Received %lu bytes of data:\r\r%@", (unsigned long)[receivedData length], [NSString stringWithUTF8String:[receivedData bytes]]);
#if DEBUG        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            static NSUInteger index = 0;
            [dataString writeToFile:[[NSString stringWithFormat:@"~/Desktop/Twitter Messages/message %d.%@", index++, kAPIFormat] stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        }
#endif
        
        // Parse data from the connection (either XML or JSON.)
        [self parseDataFromConnection:connection];
    }
    
    // Release the connection.
    [mConnections removeObjectForKey:connID];
	if ([self isValidDelegateForSelector:@selector(connectionFinished:)])
		[mDelegate connectionFinished:connID];
}



@end

