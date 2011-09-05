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
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(user, ECTwitterUser*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (void)addTweet: (ECTwitterTweet*) tweet;

- (void)refresh;

@end
