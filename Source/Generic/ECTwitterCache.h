// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

@class ECTwitterImage;
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
@property (nonatomic, retain) NSMutableDictionary* authenticated;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithEngine:(ECTwitterEngine*)engine;

- (ECTwitterUser*)	addOrRefreshUserWithInfo:(NSDictionary*)info;
- (ECTwitterTweet*)addOrRefreshTweetWithInfo:(NSDictionary*)info;

- (ECTwitterTweet*)	tweetWithID:(ECTwitterID*)tweetID;
- (ECTwitterUser*)userWithID:(ECTwitterID*)userID;
- (ECTwitterUser*)userWithID:(ECTwitterID*)userID requestIfMissing:(BOOL)requestIfMissing;
- (ECTwitterImage*)		imageWithID:(ECTwitterID*)imageID URL:(NSURL*)url;

- (void)			setFavouritedStateForTweet:(ECTwitterTweet*)tweet to:(BOOL) state;

- (void)			save;
- (void)			load;

+ (ECTwitterCache*)decodingCache;

// --------------------------------------------------------------------------
// Notifications
// --------------------------------------------------------------------------

extern NSString *const ECTwitterUserUpdated;
extern NSString *const ECTwitterTweetUpdated;
extern NSString *const ECTwitterTimelineUpdated;

@end
