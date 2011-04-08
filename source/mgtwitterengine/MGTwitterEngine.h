//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineDelegate.h"
#import "OAToken.h"

#import <ECFoundation/ECProperties.h>

@class ECTwitterAuthentication;

@interface MGTwitterEngine : NSObject
{
    __weak NSObject <MGTwitterEngineDelegate>*  mDelegate;
    NSMutableDictionary*                        mConnections;   // MGTwitterHTTPURLConnection objects
	
    ECPropertyVariable(secure, BOOL);
    ECPropertyVariable(authentication, ECTwitterAuthentication*);
    ECPropertyVariable(apiDomain, NSString*);
    ECPropertyVariable(searchDomain, NSString*);
    ECPropertyVariable(clientName, NSString*);
    ECPropertyVariable(clientVersion, NSString*);
    ECPropertyVariable(clientURL, NSString*);
    ECPropertyVariable(clientToken, NSString*);
}

ECPropertyAssigned(secure, BOOL);
ECPropertyRetained(authentication, ECTwitterAuthentication*);
ECPropertyRetained(apiDomain, NSString*);
ECPropertyRetained(searchDomain, NSString*);

#pragma mark Class management

- (MGTwitterEngine *)initWithDelegate:(NSObject*)delegate;
- (void)setClientName:(NSString*)name version:(NSString*)version URL:(NSString*)url;
- (NSString*) request:(NSString*)path parameters:(NSDictionary*)params method:(NSString*)method;

// Connection methods
- (NSUInteger)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnection:(NSString*)identifier;
- (void)closeAllConnections;

@end
