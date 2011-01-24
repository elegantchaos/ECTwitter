// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class ECTwitterTweet;

@interface ECTwitterTimeline : NSObject 
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

- (void)				addTweet: (ECTwitterTweet*) tweet;
- (ECTwitterTimeline*)	sortedWithSelector: (SEL) selector;

@end
