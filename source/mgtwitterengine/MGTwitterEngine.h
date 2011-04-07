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

@class ECTwitterAuthentication;

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
	
    ECPropertyVariable(authentication, ECTwitterAuthentication*);
}

ECPropertyRetained(authentication, ECTwitterAuthentication*);

#pragma mark Class management

// Constructors
+ (MGTwitterEngine *)twitterEngineWithDelegate:(NSObject *)delegate;
- (MGTwitterEngine *)initWithDelegate:(NSObject *)delegate;

// Configuration and Accessors
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

@interface MGTwitterEngine (Generic)

- (NSString *) genericRequestWithMethod:(NSString *)method path:(NSString *)path queryParameters:(NSDictionary *)params body:(NSString *)body;

@end
