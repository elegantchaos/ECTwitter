// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <ECUnitTests/ECUnitTests.h>
#import <ECTwitter/ECTwitter.h>

@interface ECTwitterEngineTests : ECTestCase

@property (assign, nonatomic) BOOL authenticated;

@end


@implementation ECTwitterEngineTests

- (NSString*)readSetting:(NSString*)name
{
    NSString* key = [NSString stringWithFormat:@"com.elegantchaos.ectwitter.%@", name];
    NSString* result = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!key)
    {
        NSLog(@"need to set authentication using: defaults write otest %@ YOUR-VALUE-HERE", key);
    }

    return result;
}
- (void)testSetup
{
    NSString* name = @"ECTwitter Unit Tests";
    NSString* version = @"1.0";
    NSURL* url = [NSURL URLWithString:@"https://http://elegantchaos.github.com/ECTwitter/Documentation"];

    NSString* key = [self readSetting:@"key"];
    NSString* secret = [self readSetting:@"secret"];
    NSString* user = [self readSetting:@"user"];
    NSString* password = [self readSetting:@"password"];

    ECTestAssertNotNil(key);
    ECTestAssertNotNil(secret);
    ECTestAssertNotNil(user);
    ECTestAssertNotNil(password);

    ECTwitterAuthentication* authentication = [[ECTwitterAuthentication alloc] initWithKey:key secret:secret];
    ECTestAssertNotNil(authentication);

    ECTwitterEngine* engine = [[ECTwitterEngine alloc] initWithAuthetication:authentication clientName:name version:version url:url];
    ECTestAssertNotNil(engine);

    [authentication release];

	ECTwitterCache* cache = [[ECTwitterCache alloc] initWithEngine: engine];
    ECTestAssertNotNil(cache);
    [cache load];
    [cache release];

    BOOL authenticatedAlready = [engine.authentication authenticateForUser:user];
    if (!authenticatedAlready)
    {
        [engine.authentication authenticateForUser:user password:password  target:self selector:@selector(authenticationHandler:)];
        [self runUntilTimeToExit];
        BOOL authenticatedNow = [engine.authentication authenticateForUser:user];
        ECTestAssertTrue(authenticatedNow);
    }

    [engine release];
}

- (void)authenticationHandler:(ECTwitterHandler*)handler
{
    [self timeToExitRunLoop];
}

@end