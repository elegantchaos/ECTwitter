// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <ECUnitTests/ECUnitTests.h>
#import <ECTwitter/ECTwitter.h>

@interface ECTwitterCacheTests : ECTestCase

@property (strong, nonatomic) NSString* user;
@property (strong, nonatomic) NSString* password;
@property (strong, nonatomic) ECTwitterCache* cache;
@property (assign, atomic) BOOL gotAuthentication;
@property (assign, atomic) BOOL gotUserUpdate;
@property (assign, atomic) BOOL gotTimelineUpdate;


@end


@implementation ECTwitterCacheTests

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

    ECTwitterEngine* engine = [[ECTwitterEngine alloc] initWithConsumerKey:key consumerSecret:secret clientName:name version:version url:url];
    ECTestAssertNotNil(engine);

    ECTwitterCache* cache = [[ECTwitterCache alloc] initWithEngine:engine];
    ECTestAssertNotNil(cache);
    self.cache = cache;

    [cache release];
    [engine release];
}

- (void)tearDown
{
    self.cache = nil;
}

- (void)userAuthenticated:(NSNotification*)notification
{
    self.gotAuthentication = YES;
    [self timeToExitRunLoop];
}

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

- (void)testAuthenticationNotCached
{
    ECTwitterUser* user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNil(user);
}


- (void)testAuthentication
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticated object:self.user];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticationFailed object:self.user];

    ECTwitterUser* user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNil(user);

    [self.cache authenticateUserWithName:self.user password:self.password];

    if (!self.gotAuthentication)
    {
        [self runUntilTimeToExit];
    }

    user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNotNil(user);
    ECTestAssertStringIsEqual(user.twitterName, self.user);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testBadAuthentication
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticated object:self.user];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticationFailed object:self.user];

    [self.cache authenticateUserWithName:self.user password:@"notmypassword"];

    ECTwitterUser* user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNil(user);

    if (!self.gotAuthentication)
    {
        [self runUntilTimeToExit];
    }

    user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNil(user);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#if 0
- (void)testCachedUser
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:nil];

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