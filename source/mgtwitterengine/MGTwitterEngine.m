//
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"
#import "ECTwitterParser.h"
#import "ECTwitterAuthentication.h"

#import <ECFoundation/NSDictionary+ECUtilities.h>

#define TWITTER_DOMAIN          @"api.twitter.com/1"
#define TWITTER_SEARCH_DOMAIN	@"search.twitter.com"
#define HTTP_POST_METHOD        @"POST"
#define MAX_MESSAGE_LENGTH      140 // Twitter recommends tweets of max 140 chars
#define MAX_NAME_LENGTH			20
#define MAX_EMAIL_LENGTH		40
#define MAX_URL_LENGTH			100
#define MAX_LOCATION_LENGTH		30
#define MAX_DESCRIPTION_LENGTH	160

#define DEFAULT_CLIENT_NAME     @"ECTwitter"
#define DEFAULT_CLIENT_VERSION  @"1.0"
#define DEFAULT_CLIENT_URL      @"http://www.elegantchaos.com/libraries/ectwitter"
#define DEFAULT_CLIENT_TOKEN	@"ectwitter"

#define URL_REQUEST_TIMEOUT     25.0 // Twitter usually fails quickly if it's going to fail at all.


@interface MGTwitterEngine (PrivateMethods)

- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSString *)_encodeString:(NSString *)string;
- (NSString*)_sendRequest:(NSURLRequest *)theRequest;
- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method path:(NSString *)path queryParameters:(NSDictionary *)params;
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection;
- (BOOL) _isValidDelegateForSelector:(SEL)selector;
- (void)parsingSucceededForRequest:(NSString *)identifier withParsedObjects:(NSArray *)parsedObjects;

@end


@implementation MGTwitterEngine

ECPropertySynthesize(authentication);

#pragma mark - Debug Channels

ECDefineDebugChannel(MGTwitterEngineChannel);


#pragma mark Constructors


+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)theDelegate
{
    return [[[self alloc] initWithDelegate:theDelegate] autorelease];
}


- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate
{
    if ((self = [super init])) {
        _delegate = newDelegate; // deliberately weak reference
        _connections = [[NSMutableDictionary alloc] initWithCapacity:0];
        _clientName = [DEFAULT_CLIENT_NAME retain];
        _clientVersion = [DEFAULT_CLIENT_VERSION retain];
        _clientURL = [DEFAULT_CLIENT_URL retain];
        _clientSourceToken = [DEFAULT_CLIENT_TOKEN retain];
        _APIDomain = [TWITTER_DOMAIN retain];
        _searchDomain = [TWITTER_SEARCH_DOMAIN retain];
        
        _secureConnection = YES;
        _clearsCookies = NO;
        
        _APIFormat = @"json";

    }
    
    return self;
}


- (void)dealloc
{
    _delegate = nil;
 
    ECPropertyDealloc(authentication);
    
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections release];
    
    [_clientName release];
    [_clientVersion release];
    [_clientURL release];
    [_clientSourceToken release];
	[_APIDomain release];
	[_APIFormat release];
	[_searchDomain release];
	
    [super dealloc];
}


#pragma mark Configuration and Accessors

- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
{
    [_clientName release];
    _clientName = [name retain];
    [_clientVersion release];
    _clientVersion = [version retain];
    [_clientURL release];
    _clientURL = [url retain];
    [_clientSourceToken release];
    _clientSourceToken = [token retain];
}


- (NSString *)APIDomain
{
	return [[_APIDomain retain] autorelease];
}


- (void)setAPIDomain:(NSString *)domain
{
	[_APIDomain release];
	if (!domain || [domain length] == 0) {
		_APIDomain = [TWITTER_DOMAIN retain];
	} else {
		_APIDomain = [domain retain];
	}
}


- (NSString *)searchDomain
{
	return [[_searchDomain retain] autorelease];
}


- (void)setSearchDomain:(NSString *)domain
{
	[_searchDomain release];
	if (!domain || [domain length] == 0) {
		_searchDomain = [TWITTER_SEARCH_DOMAIN retain];
	} else {
		_searchDomain = [domain retain];
	}
}

- (BOOL)usesSecureConnection
{
    return _secureConnection;
}


- (void)setUsesSecureConnection:(BOOL)flag
{
    _secureConnection = flag;
}


- (BOOL)clearsCookies
{
	return _clearsCookies;
}


- (void)setClearsCookies:(BOOL)flag
{
	_clearsCookies = flag;
}

#pragma mark Connection methods


- (NSUInteger)numberOfConnections
{
    return [_connections count];
}


- (NSArray *)connectionIdentifiers
{
    return [_connections allKeys];
}


- (void)closeConnection:(NSString *)connectionIdentifier
{
    MGTwitterHTTPURLConnection *connection = [_connections objectForKey:connectionIdentifier];
    if (connection) {
        [connection cancel];
        [_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
}


- (void)closeAllConnections
{
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections removeAllObjects];
}


#pragma mark Utility methods


- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
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
             name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}


- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
                                                                 (CFStringRef)string, 
                                                                 NULL, 
                                                                 (CFStringRef)@";/?:@&=$+{}<>,",
                                                                 kCFStringEncodingUTF8);
    return [result autorelease];
}

#pragma mark Request sending methods

-(NSString*)_sendRequest:(NSURLRequest *)theRequest;
{
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest delegate:self ];
    
    if (!connection) {
        return nil;
    } else {
        [_connections setObject:connection forKey:[connection identifier]];
        [connection release];
    }
	
	if ([self _isValidDelegateForSelector:@selector(connectionStarted:)])
		[_delegate connectionStarted:[connection identifier]];
    
    return [connection identifier];
}


#pragma mark Base Request 
- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path
                                queryParameters:(NSDictionary *)params 
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
    if (params && ![method isEqualToString:HTTP_POST_METHOD]) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
    
	BOOL isSearch = NO; // (requestType == MGTwitterSearchRequest || requestType == MGTwitterSearchCurrentTrendsRequest);
	NSString* domain = isSearch ? _searchDomain : _APIDomain;
	NSString* connectionType = (_secureConnection && !isSearch) ? @"https" : @"http";
		
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
		[theRequest setTimeoutInterval:URL_REQUEST_TIMEOUT];
	}
    else
    {
		theRequest = [NSMutableURLRequest requestWithURL:finalURL 
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:URL_REQUEST_TIMEOUT];
	}
    if (method) {
        [theRequest setHTTPMethod:method];
    }
    
    [theRequest setHTTPShouldHandleCookies:NO];
    
    // Set headers for client information, for tracking purposes at Twitter.
    [theRequest setValue:_clientName    forHTTPHeaderField:@"X-Twitter-Client"];
    [theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
    [theRequest setValue:_clientURL     forHTTPHeaderField:@"X-Twitter-Client-URL"];
	
    [theRequest setValue:contentType    forHTTPHeaderField:@"Content-Type"];
    	
    return theRequest;
}

#pragma mark Parsing methods

- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSData* jsonData = [[connection data] copy];
    NSString* identifier = [[connection identifier] copy];

	ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: jsonData = %@ from %@", [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease], [connection URL]);

    ECTwitterParser* parser = [[ECTwitterParser alloc] initWithDelegate:_delegate options:MGTwitterEngineDeliveryAllResultsOption];
    [parser parseData:jsonData identifier:identifier];
    [parser release];

    [jsonData release];
    [identifier release];
}

#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}


#pragma mark NSURLConnection delegate methods


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
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
    
        ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: (%ld) [%@]:\r%@", 
              (long)[resp statusCode], 
              [NSHTTPURLResponse localizedStringForStatusCode:[((NSHTTPURLResponse *)response) statusCode]], 
              [((NSHTTPURLResponse *)response) allHeaderFields]);
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the receivedData.
    [connection appendData:data];
}


- (void)connection:(MGTwitterHTTPURLConnection *)connection didFailWithError:(NSError *)error
{
	NSString *connectionIdentifier = [connection identifier];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)]){
		[_delegate requestFailed:connectionIdentifier
					   withError:error];
	}
    
    // Release the connection.
    [_connections removeObjectForKey:connectionIdentifier];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connectionIdentifier];
}


- (void)connectionDidFinishLoading:(MGTwitterHTTPURLConnection *)connection
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
		if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
			[_delegate requestFailed:[connection identifier] withError:error];

        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
        return;
    }

	NSString *connID = nil;
	connID = [connection identifier];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:connID];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
		// Dump data as string for debugging.
		ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: Succeeded! Received %lu bytes of data:\r\r%@", (unsigned long)[receivedData length], [NSString stringWithUTF8String:[receivedData bytes]]);
#if DEBUG        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            static NSUInteger index = 0;
            [dataString writeToFile:[[NSString stringWithFormat:@"~/Desktop/Twitter Messages/message %d.%@", index++, _APIFormat] stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        }
#endif
        
        // Parse data from the connection (either XML or JSON.)
        [self _parseDataForConnection:connection];
    }
    
    // Release the connection.
    [_connections removeObjectForKey:connID];
	if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
		[_delegate connectionFinished:connID];
}


#pragma mark -
#pragma mark Generic API methods
#pragma mark -

- (NSString *) genericRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
{

	NSString *fullPath = [NSString stringWithFormat:@"%@.%@", path, _APIFormat];
    
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
	if (!body && isPOST)
	{
		body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
	}
	
    NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method path:fullPath queryParameters:params];
    
    // Set the request body if this is a POST request.
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
        NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}
        
        if (finalBody) {
            [theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
			ECDebug(MGTwitterEngineChannel, @"MGTwitterEngine: finalBody = %@", finalBody);
        }
    }
	
	return [self _sendRequest:theRequest];
}


@end

