// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------


#if TARGET_OS_IPHONE

@interface ECTwitterImage : UIImage

#else

@interface ECTwitterImage : NSImage
#endif

- (id)initWithContentsOfURL:(NSURL *)url;

@end
