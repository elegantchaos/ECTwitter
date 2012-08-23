// --------------------------------------------------------------------------
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterImage.h"

@implementation ECTwitterImage

#if TARGET_OS_IPHONE

- (id)initWithContentsOfURL:(NSURL *)url
{
    NSData* data = [NSData dataWithContentsOfURL:url];
    self = [super initWithData:data];

    return self;
}

#else

- (id)initWithContentsOfURL:(NSURL *)url
{
    return [super initWithContentsOfURL:url];
}

#endif


@end