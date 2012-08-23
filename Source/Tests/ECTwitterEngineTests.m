// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <ECUnitTests/ECUnitTests.h>
#import <ECTwitter/ECTwitter.h>

@interface ECTwitterEngineTests : ECTestCase

@end


@implementation ECTwitterEngineTests

- (void)testSetup
{
    NSString* name = @"ECTwitter Unit Tests";
    NSString* version = @"1.0";
    NSURL* url = [NSURL URLWithString:@"https://http://elegantchaos.github.com/ECTwitter/Documentation"];

    NSString* key = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.elegantchaos.ectwitter.key"];
    if (!key)
    {
        NSLog(@"need to set authentication using: defaults write otest com.elegantchaos.ectwitter.key YOUR-KEY-HERE");
    }

    NSString* secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.elegantchaos.ectwitter.secret"];
    if (!secret)
    {
        NSLog(@"need to set authentication using: defaults write otest com.elegantchaos.ectwitter.secret YOUR-SECRET-HERE");
    }

    ECTestAssertNotNil(key);
    ECTestAssertNotNil(secret);

    ECTwitterAuthentication* authentication = [[ECTwitterAuthentication alloc] initWithKey:key secret:secret];
    ECTestAssertNotNil(authentication);

    ECTwitterEngine* engine = [[ECTwitterEngine alloc] initWithAuthetication:authentication clientName:name version:version url:url];
    ECTestAssertNotNil(engine);

    [engine release];

}
@end