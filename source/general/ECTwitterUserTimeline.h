// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"

@class ECTwitterUser;

@interface ECTwitterUserTimeline : ECTwitterTimeline 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, assign) FetchMethod method;
@property (nonatomic, retain) ECTwitterUser* user;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)init;
- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;
- (void)addTweet: (ECTwitterTweet*) tweet;
- (void)refresh;
- (void)trackPosts;
- (void)trackHome;

@end
