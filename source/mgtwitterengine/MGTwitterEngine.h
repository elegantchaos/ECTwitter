//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineGlobalHeader.h"
#import "MGTwitterEngineDelegate.h"
#import "OAToken.h"

#import <ECFoundation/ECProperties.h>

@interface MGTwitterEngine : NSObject
{
    __weak NSObject <MGTwitterEngineDelegate> *_delegate;
    NSMutableDictionary *_connections;   // MGTwitterHTTPURLConnection objects
    NSString *_clientName;
    NSString *_clientVersion;
    NSString *_clientURL;
    NSString *_clientSourceToken;
	NSString *_APIDomain;
	NSString *_searchDomain;
	NSString *_APIFormat;
    BOOL _secureConnection;
	BOOL _clearsCookies;
	
	// OAuth
	NSString *_consumerKey;
	NSString *_consumerSecret;
	OAToken  *_accessToken;
	
	// basic auth - deprecated
	NSString *_username;
    NSString *_password;
    
    ECPropertyVariable(oauthRequest, NSString*);
}

ECPropertyRetained(oauthRequest, NSString*);

#pragma mark Class management

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
+ (NSString *)version; // returns the version of MGTwitterEngine
- (NSString *)clientName; // see README.txt for info on clientName/Version/URL/SourceToken
- (NSString *)clientVersion;
- (NSString *)clientURL;
- (NSString *)clientSourceToken;
- (void)setClientName:(NSString *)name version:(NSString *)version URL:(NSString *)url token:(NSString *)token;
- (NSString *)APIDomain;
- (void)setAPIDomain:(NSString *)domain;
- (NSString *)searchDomain;
- (void)setSearchDomain:(NSString *)domain;
- (BOOL)usesSecureConnection; // YES = uses HTTPS, default is YES
- (void)setUsesSecureConnection:(BOOL)flag;
- (BOOL)clearsCookies; // YES = deletes twitter.com cookies when setting username/password, default is NO (see README.txt)
- (void)setClearsCookies:(BOOL)flag;

// Connection methods
- (NSUInteger)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString *)identifier;
- (void)closeAllConnections;

@end

@interface MGTwitterEngine (OAuth)

- (NSString *)username;
- (void)setUsername:(NSString *) newUsername;

- (void)setConsumerKey:(NSString *)key secret:(NSString *)secret;
- (NSString *)consumerKey;
- (NSString *)consumerSecret;

- (void)setAccessToken: (OAToken *)token;
- (OAToken *)accessToken;

// XAuth login - NOTE: You MUST email Twitter with your application's OAuth key/secret to
// get OAuth access. This will not work if you don't do this.
- (NSString *)getXAuthAccessTokenForUsername:(NSString *)username 
									password:(NSString *)password;

@end

@interface MGTwitterEngine (Generic)

- (NSString *) genericRequestWithMethod:(NSString *)method path:(NSString *)path queryParameters:(NSDictionary *)params body:(NSString *)body;

@end
