// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class ECTwitterTweet;
@class ECTwitterUser;
@class ECTwitterEngine;
@class ECTwitterID;

@interface ECTwitterCache : NSObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) ECTwitterEngine* engine;
@property (nonatomic, retain) NSMutableDictionary* tweets;
@property (nonatomic, retain) NSMutableDictionary* users;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithEngine: (ECTwitterEngine*) engine;

- (ECTwitterUser*)	addOrRefreshUserWithInfo: (NSDictionary*) info;
- (ECTwitterTweet*) addOrRefreshTweetWithInfo: (NSDictionary*) info;

- (ECTwitterTweet*)	tweetWithID: (ECTwitterID*) tweetID;
- (ECTwitterUser*)userWithID:(ECTwitterID*)userID;
- (ECTwitterUser*)userWithID:(ECTwitterID*)userID requestIfMissing:(BOOL)requestIfMissing;
- (NSImage*)		imageWithID: (ECTwitterID*) imageID URL: (NSURL*) url;

- (void)			setFavouritedStateForTweet: (ECTwitterTweet*) tweet to: (BOOL) state;

- (void)			save;
- (void)			load;

+ (ECTwitterCache*) decodingCache;

// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const ECTwitterUserUpdated;
extern NSString *const ECTwitterTweetUpdated;
extern NSString *const ECTwitterTimelineUpdated;

@end
