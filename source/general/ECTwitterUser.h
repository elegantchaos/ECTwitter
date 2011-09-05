// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

#import <ECFoundation/ECProperties.h>

@class ECTwitterID;
@class ECTwitterTimeline;
@class ECTwitterTweet;
@class ECTwitterUserList;

@interface ECTwitterUser : ECTwitterCachedObject  
{
	ECPropertyVariable(cachedImage, NSImage*);
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(followers, ECTwitterUserList*);
	ECPropertyVariable(friends, ECTwitterUserList*);
	ECPropertyVariable(mentions, ECTwitterTimeline*);
    ECPropertyVariable(posts, ECTwitterTimeline*);
	ECPropertyVariable(timeline, ECTwitterTimeline*);
	ECPropertyVariable(twitterID, ECTwitterID*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(cachedImage, NSImage*);
ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(followers, ECTwitterUserList*);
ECPropertyRetained(friends, ECTwitterUserList*);
ECPropertyRetained(mentions, ECTwitterTimeline*);
ECPropertyRetained(posts, ECTwitterTimeline*);
ECPropertyRetained(timeline, ECTwitterTimeline*);
ECPropertyRetained(twitterID, ECTwitterID*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (id)				initWithContentsOfURL: (NSURL*) url inCache: (ECTwitterCache*) cache;
- (id)				initWithID: (ECTwitterID*) tweetID inCache: (ECTwitterCache*) cache;

- (void)			refreshWithInfo: (NSDictionary*) info;

- (BOOL)			gotData;

- (NSString*)		description;
- (NSString*)		name;
- (NSString*)		twitterName;
- (NSString*)		longDisplayName;

- (NSString*)		bio;

- (NSImage*)		image;

- (void)			addTweet: (ECTwitterTweet*) tweet;
- (void)			addPost: (ECTwitterTweet*) tweet;
- (void)			addFriend: (ECTwitterUser*) user;
- (void)			addFollower: (ECTwitterUser*) user;

- (void)			requestPosts;
- (void)			refreshPosts;

- (void)            requestFollowers;
- (void)            requestFriends;

- (void)			saveTo: (NSURL*) url;

@end
