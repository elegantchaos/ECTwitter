// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"

@class ECTwitterUser;

@interface ECTwitterUserTimeline : ECTwitterTimeline 
{
	ECPropertyVariable(user, ECTwitterUser*);
	ECPropertyVariable(methods, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(user, ECTwitterUser*);
ECPropertyRetained(method, NSString*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (void)addTweet: (ECTwitterTweet*) tweet;
- (void)refresh;
- (void)trackPosts;
- (void)trackHome;

@end
