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

ECDeclareDebugChannel(TwitterCacheChannel);
ECDeclareDebugChannel(AuthenticationChannel);

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
    ECEnableChannel(TwitterCacheChannel);
    ECEnableChannel(AuthenticationChannel);


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

- (void)authenticate
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticated object:self.user];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userAuthenticated:) name:ECTwitterUserAuthenticationFailed object:self.user];

    [self.cache authenticateUserWithName:self.user password:self.password];

    if (!self.gotAuthentication)
    {
        [self runUntilTimeToExit];
    }
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
    ECTwitterUser* user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNil(user);

    [self authenticate];

    user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertNotNil(user);
    ECTestAssertStringIsEqual(user.twitterID.string, @"776194513");
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

- (void)testAuthenticatedUserInfo
{
    // user update may come in whilst we're authenticating, and before we have a user object, so listen for updates on any user
    // (normally, for efficiency, we want to listen only for the update for a given user)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:nil];

    [self authenticate];

    if (!self.gotUserUpdate)
    {
        [self runUntilTimeToExit];
    }

    ECTwitterUser* user = [self.cache authenticatedUserWithName:self.user];
    ECTestAssertTrue(user.gotData);
    ECTestAssertStringIsEqual(user.twitterID.string, @"776194513");
    ECTestAssertStringIsEqual(user.twitterName, self.user);
    ECTestAssertStringIsEqual(user.name, @"ECT Unit Tests");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testOtherUserInfo
{
    [self authenticate];

    ECTwitterID* userID = [ECTwitterID idFromString:@"61523"];
    ECTwitterUser* user = [self.cache userWithID:userID];
    ECTestAssertNotNil(user);
    ECTestAssertFalse(user.gotData);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:user];

    if (!self.gotUserUpdate)
    {
        [self runUntilTimeToExit];
    }

    ECTestAssertTrue(user.gotData);
    ECTestAssertStringIsEqual(user.name, @"Sam Deane");
    ECTestAssertStringIsEqual(user.twitterName, @"samdeane");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testTimeline
{
    [self authenticate];

    ECTwitterUser* authenticatedUser = [self.cache authenticatedUserWithName:self.user];
    [self.cache setDefaultAuthenticatedUser:authenticatedUser];

    ECTwitterID* userID = [ECTwitterID idFromString:@"61523"];
    ECTwitterUser* user = [self.cache userWithID:userID];
    ECTestAssertNotNil(user);
    ECTestAssertFalse(user.gotData);

    ECTwitterTimeline* timeline = user.timeline;
    ECTestAssertIsEmpty(timeline);
    [timeline refresh];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:ECTwitterUserUpdated object:user];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timelineUpdated:) name:ECTwitterTimelineUpdated object:timeline];

    while (!(self.gotUserUpdate && self.gotTimelineUpdate))
    {
        [self runUntilTimeToExit];
    }

    ECTestAssertTrue(user.gotData);
    ECTestAssertNotEmpty(timeline);

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end