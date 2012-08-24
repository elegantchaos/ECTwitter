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
@property (assign, atomic) BOOL gotUserUpdate;
@property (assign, atomic) BOOL gotTimelineUpdate;

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

#if 0
- (void)userUpdated:(NSNotification*)notification
{
    self.gotUserUpdate = YES;
    [self timeToExitRunLoop];
}

- (void)timelineUpdated:(NSNotification*)notification
{
    self.gotTimelineUpdate = YES;
    [self timeToExitRunLoop];
}

- (void)testCachedUser
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:nil];
    ECTwitterCache* cache = [[ECTwitterCache alloc] initWithEngine:self.engine];
    ECTestAssertNotNil(cache);

    ECTwitterID* userID = [ECTwitterID idFromString:@"61523"];
    ECTwitterUser* user = [cache userWithID:userID];
    ECTestAssertNotNil(user);
    ECTestAssertFalse(user.gotData);

    [self runUntilTimeToExit];

    ECTestAssertTrue(user.gotData);
    ECTestAssertStringIsEqual(user.name, @"Sam Deane");
    ECTestAssertStringIsEqual(user.twitterName, @"samdeane");

    [cache release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testTimeline
{
    [self authenticate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timelineUpdated:) name:ECTwitterTimelineUpdated object:nil];
    ECTwitterCache* cache = [[ECTwitterCache alloc] initWithEngine:self.engine];
    ECTestAssertNotNil(cache);

    ECTwitterID* userID = [ECTwitterID idFromString:@"61523"];
    ECTwitterUser* user = [cache userWithID:userID];
    ECTestAssertNotNil(user);
    ECTestAssertFalse(user.gotData);
    ECTwitterTimeline* timeline = user.timeline;
    ECTestAssertIsEmpty(timeline);
    [timeline refresh];
    
    while (!(self.gotUserUpdate && self.gotTimelineUpdate))
    {
        [self runUntilTimeToExit];
    }

    ECTestAssertTrue(user.gotData);
    ECTestAssertNotEmpty(timeline);

    [cache release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#endif

@end