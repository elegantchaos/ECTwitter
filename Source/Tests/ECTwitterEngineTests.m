// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <ECUnitTests/ECUnitTests.h>
#import <ECTwitter/ECTwitter.h>

@interface ECTwitterEngineTests : ECTestCase

@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) ECTwitterAuthentication* authentication;
@property (strong, nonatomic) ECTwitterEngine* engine;
@property (assign, atomic) BOOL gotAuthentication;

@end


@implementation ECTwitterEngineTests

- (NSString*)readSetting:(NSString*)name
{
    [[NSUserDefaults standardUserDefaults] setObject:@"test" forKey:@"test"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString* key = [NSString stringWithFormat:@"com.elegantchaos.ectwitter.%@", name];
    NSString* result = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!key)
    {
        NSLog(@"need to set authentication using: defaults write otest %@ YOUR-VALUE-HERE", key);
    }

    return result;
}

- (void)setUp
{
    NSString* name = @"ECTwitter Unit Tests";
    NSString* version = @"1.0";
    NSURL* url = [NSURL URLWithString:@"https://http://elegantchaos.github.com/ECTwitter/Documentation"];

    NSString* key = [self readSetting:@"key"];
    NSString* secret = [self readSetting:@"secret"];
    self.user = [self readSetting:@"user"];
    self.password = [self readSetting:@"password"];

    ECTestAssertNotNil(key);
    ECTestAssertNotNil(secret);
    ECTestAssertNotNil(self.user);
    ECTestAssertNotNil(self.password);

    self.engine = [[[ECTwitterEngine alloc] initWithConsumerKey:key consumerSecret:secret clientName:name version:version url:url] autorelease];
    ECTestAssertNotNil(self.engine);
}

- (void)tearDown
{
 self.engine = nil;
 self.authentication = nil;
}

- (void)authenticate
{
    ECTwitterAuthentication* authentication = [[ECTwitterAuthentication alloc] initWithEngine:self.engine];
    [authentication authenticateForUser:self.user password:self.password handler:^(ECTwitterHandler*handler) {
        self.gotAuthentication = YES;
        [self timeToExitRunLoop];

        ECTestAssertIntegerIsEqual(handler.status, StatusResults);

        NSDictionary* info = handler.result;

        ECTestAssertStringIsEqual([info objectForKey:@"user_id"], @"776194513");
        }];

    if (!self.gotAuthentication)
    {
        [self runUntilTimeToExit];
    }

    self.authentication = authentication;
    [authentication release];
}

- (void)testAuthentication
{
    [self authenticate];

    BOOL authenticatedNow = [self.authentication isAuthenticated];
    ECTestAssertTrue(authenticatedNow);
}

- (void)testAuthenticationFailure
{
    ECTwitterAuthentication* authentication = [[ECTwitterAuthentication alloc] initWithEngine:self.engine];
    [authentication authenticateForUser:@"samdeane" password:@"not my password"  handler:^(ECTwitterHandler*handler) {
        self.gotAuthentication = YES;
        [self timeToExitRunLoop];
        ECTestAssertIntegerIsEqual(handler.status, StatusFailed);
        NSLog(@"authentication error %@", [handler errorString]);
    }];

    if (!self.gotAuthentication)
    {
        [self runUntilTimeToExit];
    }

    [authentication release];
}

- (void)testUserInfo
{
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"samdeane", @"screen_name", nil];
    [self.engine callGetMethod:@"users/show" parameters:parameters extra:nil handler:^(ECTwitterHandler *handler) {

        if (handler.status == StatusResults)
        {
            NSDictionary* userData = handler.result;
            ECTestAssertStringIsEqual([userData objectForKey:@"id_str"], @"61523");
        }

        [self timeToExitRunLoop];

    }];

    [self runUntilTimeToExit];

}

@end