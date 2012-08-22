//
//  MGTwitterEngine.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 10/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterEngineDelegate.h"
#import "OAToken.h"

@class ECTwitterAuthentication;

@interface MGTwitterEngine : NSObject
{
    __weak NSObject <MGTwitterEngineDelegate>*  mDelegate;
    NSMutableDictionary*                        mConnections;   // MGTwitterHTTPURLConnection objects
}

@property (assign, nonatomic) BOOL secure;
@property (strong, nonatomic) ECTwitterAuthentication* authentication;
@property (strong, nonatomic) NSString* apiDomain;
@property (strong, nonatomic) NSString* searchDomain;

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
