// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class ECTwitterID;
@class ECTwitterUserTimeline;
@class ECTwitterUserMentionsTimeline;
@class ECTwitterTweet;
@class ECTwitterUserList;

@interface ECTwitterUser : ECTwitterCachedObject

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSImage* cachedImage;
@property (nonatomic, retain) NSDictionary* data;
@property (nonatomic, retain) ECTwitterUserList* followers;
@property (nonatomic, retain) ECTwitterUserList* friends;
@property (nonatomic, retain) ECTwitterUserMentionsTimeline* mentions;
@property (nonatomic, retain) ECTwitterUserTimeline* posts;
@property (nonatomic, retain) ECTwitterUserTimeline* timeline;
@property (nonatomic, retain) ECTwitterID* twitterID;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (id)              initWithCoder:(NSCoder*)coder;
- (id)				initWithID: (ECTwitterID*) tweetID inCache: (ECTwitterCache*) cache;

- (void)			refreshWithInfo: (NSDictionary*) info;

- (BOOL)			gotData;

- (NSString*)		description;
- (NSString*)		name;
- (NSString*)		twitterName;
- (NSString*)		longDisplayName;

- (NSString*)		bio;

- (NSImage*)		image;

- (void)			addFriend:(ECTwitterUser*)user;
- (void)			addFollower:(ECTwitterUser*)user;

- (void)            requestFollowers;
- (void)            requestFriends;

@end
