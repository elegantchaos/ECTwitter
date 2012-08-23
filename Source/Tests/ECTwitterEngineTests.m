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

    self.authentication = [[ECTwitterAuthentication alloc] initWithKey:key secret:secret];
    ECTestAssertNotNil(self.authentication);

    self.engine = [[ECTwitterEngine alloc] initWithAuthetication:self.authentication clientName:name version:version url:url];
    ECTestAssertNotNil(self.engine);

    ECTwitterCache* cache = [[ECTwitterCache alloc] initWithEngine:self.engine];
    ECTestAssertNotNil(cache);
    [cache load];
    [cache release];
}

- (void)tearDown
{
    self.authentication = nil;
    self.engine = nil;
}

- (void)testAuthentication
{
    BOOL authenticatedAlready = [self.authentication authenticateForUser:self.user];
    if (!authenticatedAlready)
    {
        [self.authentication authenticateForUser:self.user password:self.password  handler:^(ECTwitterHandler*handler) {
            [self timeToExitRunLoop];
        }];

        [self runUntilTimeToExit];
        BOOL authenticatedNow = [self.authentication authenticateForUser:self.user];
        ECTestAssertTrue(authenticatedNow);
    }
}

- (void)testAuthenticationFailure
{
    BOOL authenticatedAlready = [self.authentication authenticateForUser:@"samdeane"];
    ECTestAssertFalse(authenticatedAlready);

    __block BOOL notAuthenticated;

    [self.authentication authenticateForUser:@"samdeane" password:@"notmypassword"  handler:^(ECTwitterHandler*handler) {

        notAuthenticated = (handler.status == StatusFailed);
        NSString* errorString = [handler errorString];
        NSLog(@"authentication rejected, as expected, with error %@", errorString);

        [self timeToExitRunLoop];
    }];

    [self runUntilTimeToExit];
}

- (void)testUserInfo
{
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:@"samdeane", @"screen_name", nil];
    [self.engine callGetMethod: @"users/show" parameters: parameters handler:^(ECTwitterHandler *handler) {

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