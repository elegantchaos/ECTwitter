// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"

@class ECTwitterUser;

@interface ECTwitterSearchTimeline : ECTwitterTimeline 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSString* text;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)init;
- (void)addTweet: (ECTwitterTweet*) tweet;
- (void)refresh;
- (void)trackPosts;
- (void)trackHome;

@end
