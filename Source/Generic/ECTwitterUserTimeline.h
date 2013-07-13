// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 24/01/2011
//
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"

@class ECTwitterUser;

@interface ECTwitterUserTimeline : ECTwitterTimeline 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, assign) FetchMethod method;
@property (strong, nonatomic) ECTwitterUser* user;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)init;
- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;
- (void)addTweet:(ECTwitterTweet*)tweet;
- (void)refresh;
- (void)trackPosts;
- (void)trackHome;

@end
