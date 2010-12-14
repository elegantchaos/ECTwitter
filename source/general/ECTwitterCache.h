// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class ECTwitterTweet;
@class ECTwitterUser;
@class ECTwitterEngine;
@class ECTwitterID;

@interface ECTwitterCache : NSObject 
{
	ECPropertyVariable(engine, ECTwitterEngine*);
	ECPropertyVariable(tweets, NSMutableDictionary*);
	ECPropertyVariable(users, NSMutableDictionary*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(engine, ECTwitterEngine*);
ECPropertyRetained(tweets, NSMutableDictionary*);
ECPropertyRetained(users, NSMutableDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithEngine: (ECTwitterEngine*) engine;

- (ECTwitterUser*)	addOrRefreshUserWithInfo: (NSDictionary*) info;
- (ECTwitterTweet*) addOrRefreshTweetWithInfo: (NSDictionary*) info;

- (ECTwitterTweet*)	tweetWithID: (ECTwitterID*) tweetID;
- (ECTwitterUser*)	userWithID: (ECTwitterID*) userID;

- (void)			setFavouritedStateForTweet: (ECTwitterTweet*) tweet to: (BOOL) state;

// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const ECTwitterUserUpdated;
extern NSString *const ECTwitterTweetUpdated;

@end
