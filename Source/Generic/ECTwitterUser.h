// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 05/08/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class ECTwitterAuthentication;
@class ECTwitterID;
@class ECTwitterImage;
@class ECTwitterUserTimeline;
@class ECTwitterUserMentionsTimeline;
@class ECTwitterTweet;
@class ECTwitterUserList;

@interface ECTwitterUser : ECTwitterCachedObject

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (strong, nonatomic) ECTwitterImage* cachedImage;
@property (strong, nonatomic) NSDictionary* data;
@property (strong, nonatomic) ECTwitterUserList* followers;
@property (strong, nonatomic) ECTwitterUserList* friends;
@property (strong, nonatomic) ECTwitterUserMentionsTimeline* mentions;
@property (strong, nonatomic) ECTwitterUserTimeline* posts;
@property (strong, nonatomic) ECTwitterUserTimeline* timeline;
@property (strong, nonatomic) ECTwitterID* twitterID;
@property (strong, nonatomic) ECTwitterAuthentication* authentication;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)initWithInfo:(NSDictionary*)info inCache:(ECTwitterCache*)cache;
- (id)initWithCoder:(NSCoder*)coder;
- (id)initWithID:(ECTwitterID*)tweetID inCache:(ECTwitterCache*)cache;

- (void)refreshWithInfo:(NSDictionary*)info;

- (BOOL)gotData;

- (NSString*)description;
- (NSString*)name;
- (NSString*)twitterName;
- (NSString*)longDisplayName;

- (NSString*)bio;

- (ECTwitterImage*)image;

- (void)addFriend:(ECTwitterUser*)user;
- (void)addFollower:(ECTwitterUser*)user;

- (void)requestFollowers;
- (void)requestFriends;

@end
