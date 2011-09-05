// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <ECFoundation/ECProperties.h>

#import "ECTwitterCachedObject.h"

@class ECTwitterTweet;
@class ECTwitterHandler;

@interface ECTwitterTimeline : ECTwitterCachedObject 
{
	ECPropertyVariable(tweets, NSMutableArray*);
	ECPropertyVariable(oldestTweet, ECTwitterTweet*);
	ECPropertyVariable(newestTweet, ECTwitterTweet*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(tweets, NSMutableArray*);
ECPropertyRetained(oldestTweet, ECTwitterTweet*);
ECPropertyRetained(newestTweet, ECTwitterTweet*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (void)refresh;
- (void) addTweet: (ECTwitterTweet*) tweet;
- (ECTwitterTimeline*)sortedWithSelector: (SEL) selector;
- (void)timelineHandler: (ECTwitterHandler*) handler;

@end
