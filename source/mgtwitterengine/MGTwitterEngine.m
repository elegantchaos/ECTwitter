//
//  MGTwitterEngine.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"
#import "MGTwitterLogging.h"
#import "OAuthConsumer.h"

#import "NSData+Base64.h"
#import "MGTwitterParserFactory.h"

#define TWITTER_DOMAIN          @"api.twitter.com/1"
#define TWITTER_SEARCH_DOMAIN	@"search.twitter.com"
#define HTTP_POST_METHOD        @"POST"
#define MAX_MESSAGE_LENGTH      140 // Twitter recommends tweets of max 140 chars
#define MAX_NAME_LENGTH			20
#define MAX_EMAIL_LENGTH		40
#define MAX_URL_LENGTH			100
#define MAX_LOCATION_LENGTH		30
#define MAX_DESCRIPTION_LENGTH	160

#define DEFAULT_CLIENT_NAME     @"MGTwitterEngine"
#define DEFAULT_CLIENT_VERSION  @"1.0"
#define DEFAULT_CLIENT_URL      @"http://mattgemmell.com/source"
#define DEFAULT_CLIENT_TOKEN	@"mgtwitterengine"

#define URL_REQUEST_TIMEOUT     25.0 // Twitter usually fails quickly if it's going to fail at all.

@interface NSDictionary (MGTwitterEngineExtensions)

-(NSDictionary *)MGTE_dictionaryByRemovingObjectForKey:(NSString *)key;

@end

@implementation NSDictionary (MGTwitterEngineExtensions)

-(NSDictionary *)MGTE_dictionaryByRemovingObjectForKey:(NSString *)key{
	NSDictionary *result = self;
	if(key){
		NSMutableDictionary *newParams = [[self mutableCopy] autorelease];
		[newParams removeObjectForKey:key];
		result = [[newParams copy] autorelease];
	}
	return result;
}

@end



@interface MGTwitterEngine (PrivateMethods)

// Utility methods
- (NSDateFormatter *)_HTTPDateFormatter;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;
- (NSDate *)_HTTPToDate:(NSString *)httpDate;
- (NSString *)_dateToHTTP:(NSDate *)date;
- (NSString *)_encodeString:(NSString *)string;

// Connection/Request methods
- (NSString*)_sendRequest:(NSURLRequest *)theRequest withRequestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType;
- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType;

- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
                                    path:(NSString *)path 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSString *)body 
                             requestType:(MGTwitterRequestType)requestType 
                            responseType:(MGTwitterResponseType)responseType;

- (NSMutableURLRequest *)_baseRequestWithMethod:(NSString *)method 
                                           path:(NSString *)path 
                                    requestType:(MGTwitterRequestType)requestType 
                                queryParameters:(NSDictionary *)params;


// Parsing methods
- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection;

// Delegate methods
- (BOOL) _isValidDelegateForSelector:(SEL)selector;

@end


@implementation MGTwitterEngine


#pragma mark Constructors


+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)theDelegate
{
    return [[[self alloc] initWithDelegate:theDelegate] autorelease];
}


- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate
{
	// TODO - should probably deprecate this form of initaliser when
	//		  and force people to provide a parser; then we can remove
	//		  all use of YAJL_AVAILABLE etc
	
	MGTwitterParserFactory* parser = nil;
	
	#if YAJL_AVAILABLE
		parser = [[MGTwitterParserFactoryYAJL alloc] init];
	#elif TOUCHJSON_AVAILABLE
		parser = [[MGTwitterParserFactoryTouchJSON alloc] init];
	#elif USE_LIBXML
		parser = [[MGTwitterParserFactoryLibXML alloc] init];
	#elif USE_NSXML
		parser = [[MGTwitterParserFactoryXML alloc] init];
	#endif
	
	return [self initWithDelegate: newDelegate parser: [parser autorelease]];
}

- (MGTwitterEngine *)initWithDelegate:(NSObject *)newDelegate parser:(MGTwitterParserFactory*) parser;
{
    if ((self = [super init])) {
		if (parser)
		{
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
			
			_parser = [parser retain];
			_APIFormat = [_parser APIFormat];
		}
		else
		{
			[self release];
			self = nil;
			NSAssert(NO, @"You must provide a parser, or define one of YAJL_AVAILABLE, TOUCHJSON_AVAILABLE, USE_LIBXML or USE_NSXML to 1 in your prefix header");
		}

    }
    
    return self;
}


- (void)dealloc
{
    _delegate = nil;
    
    [[_connections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [_connections release];
    
    [_username release];
    [_password release];
    [_clientName release];
    [_clientVersion release];
    [_clientURL release];
    [_clientSourceToken release];
	[_APIDomain release];
	[_APIFormat release];
	[_searchDomain release];
    [_parser release];
	
    [super dealloc];
}


#pragma mark Configuration and Accessors


+ (NSString *)version
{
    // 1.0.0 = 22 Feb 2008
    // 1.0.1 = 26 Feb 2008
    // 1.0.2 = 04 Mar 2008
    // 1.0.3 = 04 Mar 2008
	// 1.0.4 = 11 Apr 2008
	// 1.0.5 = 06 Jun 2008
	// 1.0.6 = 05 Aug 2008
	// 1.0.7 = 28 Sep 2008
	// 1.0.8 = 01 Oct 2008
    return @"1.0.8";
}

- (NSString *)clientName
{
    return [[_clientName retain] autorelease];
}


- (NSString *)clientVersion
{
    return [[_clientVersion retain] autorelease];
}


- (NSString *)clientURL
{
    return [[_clientURL retain] autorelease];
}


- (NSString *)clientSourceToken
{
    return [[_clientSourceToken retain] autorelease];
}


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

- (MGTwitterParserFactory *) parser
{
	return [[_parser retain] autorelease];
}


- (void)setParser:(MGTwitterParserFactory *)parser
{
	[_parser release];
	_parser = [parser retain];
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


- (NSDateFormatter *)_HTTPDateFormatter
{
    // Returns a formatter for dates in HTTP format (i.e. RFC 822, updated by RFC 1123).
    // e.g. "Sun, 06 Nov 1994 08:49:37 GMT"
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	//[dateFormatter setDateFormat:@"%a, %d %b %Y %H:%M:%S GMT"]; // won't work with -init, which uses new (unicode) format behaviour.
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss GMT"];
	return dateFormatter;
}


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


- (NSDate *)_HTTPToDate:(NSString *)httpDate
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter dateFromString:httpDate];
}


- (NSString *)_dateToHTTP:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [self _HTTPDateFormatter];
    return [dateFormatter stringFromDate:date];
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


- (NSString *)getImageAtURL:(NSString *)urlString
{
    // This is a method implemented for the convenience of the client, 
    // allowing asynchronous downloading of users' Twitter profile images.
	NSString *encodedUrlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!url) {
        return nil;
    }
    
    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:URL_REQUEST_TIMEOUT];
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:MGTwitterImageRequest 
                                                        responseType:MGTwitterImage];
    
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


#pragma mark Request sending methods

#define SET_AUTHORIZATION_IN_HEADER 0

- (NSString *)_sendRequestWithMethod:(NSString *)method 
                                path:(NSString *)path 
                     queryParameters:(NSDictionary *)params 
                                body:(NSString *)body 
                         requestType:(MGTwitterRequestType)requestType 
                        responseType:(MGTwitterResponseType)responseType
{

    NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method 
                                                              path:path
													requestType:requestType 
                                                   queryParameters:params];
    
    // Set the request body if this is a POST request.
    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
    if (isPOST) {
        // Set request body, if specified (hopefully so), with 'source' parameter if appropriate.
        NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}

        // if using OAuth, Twitter already knows your application's name, so don't send it
        if (_clientSourceToken && _accessToken == nil) {
            finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
                                                            (body) ? @"&" : @"" , 
                                                            _clientSourceToken]];
        }
        
        if (finalBody) {
            [theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
			MGTWITTER_LOG(@"MGTwitterEngine: finalBody = %@", finalBody);
        }
    }
	
	return [self _sendRequest:theRequest withRequestType:requestType responseType:responseType];
}

-(NSString*)_sendRequest:(NSURLRequest *)theRequest withRequestType:(MGTwitterRequestType)requestType responseType:(MGTwitterResponseType)responseType;
{
    
    // Create a connection using this request, with the default timeout and caching policy, 
    // and appropriate Twitter request and response types for parsing and error reporting.
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
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


- (NSString *)_sendDataRequestWithMethod:(NSString *)method 
                                    path:(NSString *)path 
                         queryParameters:(NSDictionary *)params 
                                filePath:(NSString *)filePath
                                    body:(NSString *)body 
                             requestType:(MGTwitterRequestType)requestType 
                            responseType:(MGTwitterResponseType)responseType
{
    
    NSMutableURLRequest *theRequest = [self _baseRequestWithMethod:method 
                                                              path:path
                                                       requestType:requestType
                                                   queryParameters:params];

    BOOL isPOST = (method && [method isEqualToString:HTTP_POST_METHOD]);
    if (isPOST) {
        NSString *boundary = @"0xKhTmLbOuNdArY";  
        NSString *filename = [filePath lastPathComponent];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        
        NSString *bodyPrefixString   = [NSString stringWithFormat:@"--%@\r\n", boundary];
        NSString *bodySuffixString   = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
        NSString *contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image\"; filename=\"%@\"\r\n", filename];
        NSString *contentImageType   = [NSString stringWithFormat:@"Content-Type: image/%@\r\n", [filename pathExtension]];
        NSString *contentTransfer    = @"Content-Transfer-Encoding: binary\r\n\r\n";
        
        
        NSMutableData *postBody = [NSMutableData data];
        
        [postBody appendData:[bodyPrefixString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        [postBody appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding ]];
        [postBody appendData:[contentImageType dataUsingEncoding:NSUTF8StringEncoding ]];
        [postBody appendData:[contentTransfer dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:imageData];
        [postBody appendData:[bodySuffixString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        
        [theRequest setHTTPBody:postBody];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil];
        [theRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    
    MGTwitterHTTPURLConnection *connection;
    
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest 
                                                            delegate:self 
                                                         requestType:requestType 
                                                        responseType:responseType];
    
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
                                    requestType:(MGTwitterRequestType)requestType 
                                queryParameters:(NSDictionary *)params 
{
	NSString *contentType = [params objectForKey:@"Content-Type"];
	if(contentType){
		params = [params MGTE_dictionaryByRemovingObjectForKey:@"Content-Type"];
	}else{
		contentType = @"application/x-www-form-urlencoded";
	}
	
    // Construct appropriate URL string.
    NSString *fullPath = [path stringByAddingPercentEscapesUsingEncoding:NSNonLossyASCIIStringEncoding];
    if (params && ![method isEqualToString:HTTP_POST_METHOD]) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
    
	BOOL isSearch = (requestType == MGTwitterSearchRequest || requestType == MGTwitterSearchCurrentTrendsRequest);
	NSString* domain = isSearch ? _searchDomain : _APIDomain;
	NSString* connectionType = (_secureConnection && !isSearch) ? @"https" : @"http";
		
#if 1 // SET_AUTHORIZATION_IN_HEADER
    NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@", 
                           connectionType,
                           domain, fullPath];
#else    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@", 
                           connectionType, 
                           [self _encodeString:_username], [self _encodeString:_password], 
                           domain, fullPath];
#endif
    
    NSURL *finalURL = [NSURL URLWithString:urlString];
    if (!finalURL) {
        return nil;
    }
    
	MGTWITTER_LOG(@"MGTwitterEngine: finalURL = %@", finalURL);

    // Construct an NSMutableURLRequest for the URL and set appropriate request method.
	NSMutableURLRequest *theRequest = nil;
    if(_accessToken){
		theRequest = [[[OAMutableURLRequest alloc] initWithURL:finalURL
													  consumer:[[(OAConsumer*) [OAConsumer alloc] initWithKey:[self consumerKey] secret:[self consumerSecret]] autorelease]
														 token:_accessToken
														 realm:nil
											 signatureProvider:nil] autorelease];
		[theRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData ];
		[theRequest setTimeoutInterval:URL_REQUEST_TIMEOUT];
	}else{
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
    
#if SET_AUTHORIZATION_IN_HEADER
	if ([self username] && [self password]) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [self username], [self password]];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[theRequest setValue:authValue forHTTPHeaderField:@"Authorization"];
	}
#endif
	
    return theRequest;
}

#pragma mark Parsing methods

- (void)_parseDataForConnection:(MGTwitterHTTPURLConnection *)connection
{
    NSData *data = [[[connection data] copy] autorelease];
    NSString *identifier = [[[connection identifier] copy] autorelease];
    MGTwitterRequestType requestType = [connection requestType];
    MGTwitterResponseType responseType = [connection responseType];

	NSURL *URL = [connection URL];

	MGTWITTER_LOG(@"MGTwitterEngine: jsonData = %@ from %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease], URL);

	if (responseType == MGTwitterOAuthToken)
	{
		OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]] autorelease];
		[self parsingSucceededForRequest:identifier ofResponseType:requestType
						 withParsedObjects:[NSArray arrayWithObject:token]];
		
	}
	else
	{
		[_parser parseData: data URL:URL identifier:identifier requestType:requestType responseType:responseType engine:self];
	}

}

#pragma mark Delegate methods

- (BOOL) _isValidDelegateForSelector:(SEL)selector
{
	return ((_delegate != nil) && [_delegate respondsToSelector:selector]);
}

#pragma mark MGTwitterParserDelegate methods

- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(MGTwitterResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
    // Forward appropriate message to _delegate, depending on responseType.
	MGTWITTER_LOG(@"parsingSucceededForRequest responseType: %d", responseType);
    switch (responseType) {
        case MGTwitterStatuses:
        case MGTwitterStatus:
			if ([self _isValidDelegateForSelector:@selector(statusesReceived:forRequest:)])
				[_delegate statusesReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterUsers:
        case MGTwitterUser:
			if ([self _isValidDelegateForSelector:@selector(userInfoReceived:forRequest:)])
				[_delegate userInfoReceived:parsedObjects forRequest:identifier];
            break;
        case MGTwitterDirectMessages:
        case MGTwitterDirectMessage:
			if ([self _isValidDelegateForSelector:@selector(directMessagesReceived:forRequest:)])
				[_delegate directMessagesReceived:parsedObjects forRequest:identifier];
            break;
		case MGTwitterMiscellaneous:
			if ([self _isValidDelegateForSelector:@selector(miscInfoReceived:forRequest:)])
				[_delegate miscInfoReceived:parsedObjects forRequest:identifier];
			break;
		case MGTwitterSearchResults:
			if ([self _isValidDelegateForSelector:@selector(searchResultsReceived:forRequest:)])
				[_delegate searchResultsReceived:parsedObjects forRequest:identifier];
			break;
		case MGTwitterSocialGraph:
			if ([self _isValidDelegateForSelector:@selector(socialGraphInfoReceived:forRequest:)])
				[_delegate socialGraphInfoReceived: parsedObjects forRequest:identifier];
			break;
		case MGTwitterUserLists:
			if ([self _isValidDelegateForSelector:@selector(userListsReceived:forRequest:)])
				[_delegate userListsReceived: parsedObjects forRequest:identifier];
			break;			
		case MGTwitterOAuthTokenRequest:
			if ([self _isValidDelegateForSelector:@selector(accessTokenReceived:forRequest:)] && [parsedObjects count] > 0)
				[_delegate accessTokenReceived:[parsedObjects objectAtIndex:0]
									forRequest:identifier];
			break;
		case MGTwitterGenericParsed:
			if ([self _isValidDelegateForSelector:@selector(genericResultsReceived:forRequest:)] && [parsedObjects count] > 0)
				[_delegate genericResultsReceived:parsedObjects forRequest:identifier];
			break;
        default:
            break;
    }
}

- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType 
                      withError:(NSError *)error
{
	if ([self _isValidDelegateForSelector:@selector(requestFailed:withError:)])
		[_delegate requestFailed:requestIdentifier withError:error];
}

- (void)parsedObject:(NSDictionary *)dictionary forRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType
{
	if ([self _isValidDelegateForSelector:@selector(receivedObject:forRequest:)])
		[_delegate receivedObject:dictionary forRequest:requestIdentifier];
}


#pragma mark NSURLConnection delegate methods


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (_username && _password && [challenge previousFailureCount] == 0 && ![challenge proposedCredential]) {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:_username password:_password 
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
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
    
    if (statusCode == 304 || [connection responseType] == MGTwitterGenericUnparsed) {
        // Not modified, or generic success.
		if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
			[_delegate requestSucceeded:[connection identifier]];
        if (statusCode == 304) {
            [self parsingSucceededForRequest:[connection identifier] 
                              ofResponseType:[connection responseType] 
                           withParsedObjects:[NSArray array]];
        }
        
        // Destroy the connection.
        [connection cancel];
		NSString *connectionIdentifier = [connection identifier];
		[_connections removeObjectForKey:connectionIdentifier];
		if ([self _isValidDelegateForSelector:@selector(connectionFinished:)])
			[_delegate connectionFinished:connectionIdentifier];
    }
    
        MGTWITTER_LOG(@"MGTwitterEngine: (%ld) [%@]:\r%@", 
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
	MGTwitterResponseType responseType = 0;
	connID = [connection identifier];
	responseType = [connection responseType];
	
    // Inform delegate.
	if ([self _isValidDelegateForSelector:@selector(requestSucceeded:)])
		[_delegate requestSucceeded:connID];
    
    NSData *receivedData = [connection data];
    if (receivedData) {
		// Dump data as string for debugging.
		MGTWITTER_LOG(@"MGTwitterEngine: Succeeded! Received %lu bytes of data:\r\r%@", (unsigned long)[receivedData length], [NSString stringWithUTF8String:[receivedData bytes]]);
#if DEBUG        
        if (NO) {
            // Dump XML to file for debugging.
            NSString *dataString = [NSString stringWithUTF8String:[receivedData bytes]];
            static NSUInteger index = 0;
            [dataString writeToFile:[[NSString stringWithFormat:@"~/Desktop/Twitter Messages/message %d.%@", index++, _APIFormat] stringByExpandingTildeInPath] 
                         atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        }
#endif
        
        if (responseType == MGTwitterImage) {
			// Create image from data.
#if TARGET_OS_IPHONE
            UIImage *image = [[[UIImage alloc] initWithData:[connection data]] autorelease];
#else
            NSImage *image = [[[NSImage alloc] initWithData:[connection data]] autorelease];
#endif
            
            // Inform delegate.
			if ([self _isValidDelegateForSelector:@selector(imageReceived:forRequest:)])
				[_delegate imageReceived:image forRequest:[connection identifier]];
        } else {
            // Parse data from the connection (either XML or JSON.)
            [self _parseDataForConnection:connection];
        }
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
    
	if (!body && method && [method isEqualToString: HTTP_POST_METHOD])
	{
		body = [self _queryStringWithBase:nil parameters:params prefixed:NO];
	}
	
	
	return [self _sendRequestWithMethod:method path:fullPath queryParameters:params body:body 
                            requestType:MGTwitterGenericRequest 
                           responseType:MGTwitterGenericParsed];	
}


@end

@implementation MGTwitterEngine (BasicAuth)

- (NSString *)username
{
    return [[_username retain] autorelease];
}

- (void)setUsername:(NSString *)newUsername
{
    // Set new credentials.
    [_username release];
    _username = [newUsername retain];
}

- (NSString *)password
{
    return [[_password retain] autorelease];
}


- (void)setUsername:(NSString *)newUsername password:(NSString *)newPassword
{
    // Set new credentials.
    [_username release];
    _username = [newUsername retain];
    [_password release];
    _password = [newPassword retain];
    
	if ([self clearsCookies]) {
		// Remove all cookies for twitter, to ensure next connection uses new credentials.
		NSString *urlString = [NSString stringWithFormat:@"%@://%@", 
							   (_secureConnection) ? @"https" : @"http", 
							   _APIDomain];
		NSURL *url = [NSURL URLWithString:urlString];
		
		NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSEnumerator *enumerator = [[cookieStorage cookiesForURL:url] objectEnumerator];
		NSHTTPCookie *cookie = nil;
		while ((cookie = [enumerator nextObject])) {
			[cookieStorage deleteCookie:cookie];
		}
	}
}

@end

@implementation MGTwitterEngine (OAuth)

- (void)setConsumerKey:(NSString *)key secret:(NSString *)secret{
	[_consumerKey autorelease];
	_consumerKey = [key copy];
	
	[_consumerSecret autorelease];
	_consumerSecret = [secret copy];
}

- (NSString *)consumerKey{
	return _consumerKey;
}

- (NSString *)consumerSecret{
	return _consumerSecret;
}

- (void)setAccessToken: (OAToken *)token{
	[_accessToken autorelease];
	_accessToken = [token retain];
}

- (OAToken *)accessToken{
	return _accessToken;
}

- (NSString *)getXAuthAccessTokenForUsername:(NSString *)username 
									password:(NSString *)password{
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
    MGTwitterHTTPURLConnection *connection;
    connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:request
                                                            delegate:self 
                                                         requestType:MGTwitterOAuthTokenRequest
                                                        responseType:MGTwitterOAuthToken];
    [request release];

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

@end


