// --------------------------------------------------------------------------
/// @author Sam Deane
/// @date 05/08/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterUser.h"

#import "ECTwitterAuthentication.h"
#import "ECTwitterID.h"
#import "ECTwitterTweet.h"
#import "ECTwitterCache.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"
#import "ECTwitterUserMentionsTimeline.h"
#import "ECTwitterUserTimeline.h"
#import "ECTwitterUserList.h"

@interface ECTwitterUser()
- (void)makeTimelines;
- (void)friendsHandler:(ECTwitterHandler*)handler;
- (void)followersHandler:(ECTwitterHandler*)handler;
- (void)followerIDsHandler:(ECTwitterHandler*)handler;
@end


@implementation ECTwitterUser

ECDefineDebugChannel(TwitterUserChannel);
ECDeclareDebugChannel(TwitterCacheCodingChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

@synthesize authentication = _authentication;
@synthesize cachedImage = _cachedImage;
@synthesize data = _data;
@synthesize followers = _followers;
@synthesize friends = _friends;
@synthesize mentions = _mentions;
@synthesize posts = _posts;
@synthesize timeline = _timeline;
@synthesize twitterID = _twitterID;

// --------------------------------------------------------------------------
/// Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithInfo:(NSDictionary*)dictionary inCache:(ECTwitterCache*)cache
{
	if ((self = [super initWithCache:cache]) != nil)
	{
		self.data = dictionary;
		self.twitterID = [ECTwitterID idFromDictionary:dictionary];
        [self makeTimelines];
	}
	
	return self;
}


// --------------------------------------------------------------------------
/// Set up from a coder.
// --------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)coder
{
    // get the user id
    ECTwitterID* userID = [coder decodeObjectForKey:@"id"];
    
    // is there already an instance with this id in the cache?
    ECTwitterCache* cache = [ECTwitterCache decodingCache];
    ECTwitterUser* existing = [cache existingUserWithID:userID];
    if (existing)
    {
        // use the cached instance instead of this one
        [self release];
        self = [existing retain];
    }
    else
    {
        // put this object into the cache now so that restoring other objects below will pick it up
        self = [super initWithCache:cache];
        [cache addUser:self withID:userID];
    }

    if (self)
    {
        self.twitterID = userID;
        self.data = [coder decodeObjectForKey:@"info"];
        self.mentions = [coder decodeObjectForKey:@"mentions"];
        self.posts = [coder decodeObjectForKey:@"posts"];
        self.timeline = [coder decodeObjectForKey:@"timeline"];
        self.friends = [coder decodeObjectForKey:@"friends"];
        self.followers = [coder decodeObjectForKey:@"followers"];
        
        ECAssert(self.timeline.user == self);
        ECAssert(self.posts.user == self);
        ECAssert(self.mentions.user == self);
    }

    ECDebug(TwitterCacheCodingChannel, @"decoded %@", self);
    return self;
}

// --------------------------------------------------------------------------
/// Set up with just an ID.
// --------------------------------------------------------------------------

- (id)initWithID:(ECTwitterID*)idIn inCache:(ECTwitterCache*)cache
{
	if ((self = [super initWithCache:cache]) != nil)
	{
		self.twitterID = idIn;
        [self makeTimelines];
	}
	
	return self;
}

// --------------------------------------------------------------------------
/// Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
    [_authentication release];
	[_cachedImage release];
	[_data release];
	[_followers release];
	[_friends release];
	[_mentions release];
	[_posts release];
	[_timeline release];
	[_twitterID release];
	
	[super dealloc];
}

// --------------------------------------------------------------------------
/// Make the main timeline associated with this user.
// --------------------------------------------------------------------------

- (void)makeTimelines
{
    ECTwitterUserTimeline* homeTimeline = [[ECTwitterUserTimeline alloc] initWithCache:self.cache];
    homeTimeline.user = self;
    self.timeline = homeTimeline;
    [homeTimeline trackHome];
    [homeTimeline release];
    
    ECTwitterUserTimeline* postsTimeline = [[ECTwitterUserTimeline alloc] initWithCache:self.cache];
    postsTimeline.user = self;
    self.posts = postsTimeline;
    [postsTimeline trackPosts];
    [postsTimeline release];
    
    ECTwitterUserMentionsTimeline* mentionsTimeline = [[ECTwitterUserMentionsTimeline alloc] initWithCache:self.cache];
    mentionsTimeline.user = self;
    self.mentions = mentionsTimeline;
    [mentionsTimeline release];
}

// --------------------------------------------------------------------------
/// Update with new info
// --------------------------------------------------------------------------

- (void) refreshWithInfo:(NSDictionary*)info
{
	self.data = info;
}

// --------------------------------------------------------------------------
/// Have we had our data filled in?
// --------------------------------------------------------------------------

- (BOOL) gotData
{
	return (self.data != nil) && ((self.data)[@"name"] != nil);
}

// --------------------------------------------------------------------------
/// Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*)description
{
	return [NSString stringWithFormat:@"<TwitterUser:%@ %@ posts:%ld timeline:%ld mentions:%ld>", self.twitterName, self.twitterID, (long) [self.posts count], (long) [self.timeline count], (long) [self.mentions count]];
}

// --------------------------------------------------------------------------
/// Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*)name
{
	return (self.data)[@"name"];
}

// --------------------------------------------------------------------------
/// Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*)twitterName
{
	return (self.data)[@"screen_name"];
}

// --------------------------------------------------------------------------
//! Set the twitter name of the user.
//! Generally this should be set already, but if we've got no data,
//! we fill in a minimal data dictionary with the name, along with
//! the ID.
// --------------------------------------------------------------------------

- (void)setTwitterName:(NSString *)twitterName
{
    if ([self gotData])
    {
        ECAssert([self.twitterName isEqualToString:twitterName]);
    }
    else
    {
        NSDictionary* data = @{@"screen_name": twitterName,
                              @"id_str": self.twitterID.string};

        self.data = data;
        [self.cache cacheUserName:self];
    }
}

// --------------------------------------------------------------------------
/// Add a friend to our friends list.
// --------------------------------------------------------------------------

- (void) addFriend:(ECTwitterUser*)user
{
	ECTwitterUserList* list = self.friends;
	if (!list)
	{
		list = [[ECTwitterUserList alloc] init];
		self.friends = list;
		[list release];
	}
	
	[list addUser:user];
}

// --------------------------------------------------------------------------
/// Add a tweet to our posts list.
// --------------------------------------------------------------------------

- (void) addFollower:(ECTwitterUser*)user
{
	ECTwitterUserList* list = self.followers;
	if (!list)
	{
		list = [[ECTwitterUserList alloc] init];
		self.followers = list;
		[list release];
	}
	
	[list addUser:user];
}

// --------------------------------------------------------------------------
/// Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFollowerIDs
{
	ECDebug(TwitterUserChannel, @"requesting followers for %@", self);
    ECAssertNonNil(self.twitterID.string);

	NSDictionary* parameters = @{@"user_id": self.twitterID.string,
								@"cursor": @"-1"};
	
	[self.cache.engine callGetMethod:@"friends/ids" parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(followerIDsHandler:) extra:nil];
}

// --------------------------------------------------------------------------
/// Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFollowers
{
	ECDebug(TwitterUserChannel, @"requesting followers for %@", self);
    ECAssertNonNil(self.twitterID.string);
	
	NSDictionary* parameters = @{@"user_id": self.twitterID.string,
								@"cursor": @"-1"};
	
	[self.cache.engine callGetMethod:@"statuses/followers" parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(followersHandler:) extra:nil];
}

// --------------------------------------------------------------------------
/// Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFriends
{
	ECDebug(TwitterUserChannel, @"requesting friends for %@", self);
    ECAssertNonNil(self.twitterID.string);
	
	NSDictionary* parameters = @{@"user_id": self.twitterID.string,
								@"cursor": @"-1"};
	
	[self.cache.engine callGetMethod:@"statuses/friends" parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(friendsHandler:) extra:nil];
}


// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) friendsHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for:%@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);
        
        NSDictionary* info = handler.result;
        NSArray* users = info[@"users"];
		for (NSDictionary* userData in users)
		{
			ECTwitterUser* user = [self.cache addOrRefreshUserWithInfo:userData];
			[self addFriend:user];
			
			ECDebug(TwitterUserChannel, @"friend info received:%@", user);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving friends for:%@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ECTwitterUserUpdated object:self];
}


// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followersHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for:%@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);

        NSDictionary* result = handler.result;
        NSArray* users = result[@"users"];
		for (NSDictionary* userData in users)
		{
			ECTwitterUser* user = [self.cache addOrRefreshUserWithInfo:userData];
			[self addFriend:user];
			
			ECDebug(TwitterUserChannel, @"friend info received:%@", user);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving friends for:%@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ECTwitterUserUpdated object:self];
}

// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followerIDsHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received followers for:%@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);

        NSDictionary* result = handler.result;
        NSArray* userIDs = result[@"ids"];
		for (NSNumber* value in userIDs)
		{
#if 0
            NSString* userIDString = [value stringValue];
            ECTwitterID* userID = [[ECTwitterID alloc] initWithString:userIDString];
            
            ECTwitterUser* user = [self.cache userWithID:userID];
			[self addFollower:user];
            [userID release];
			
			ECDebug(TwitterUserChannel, @"follower info received:%@", user);
#endif
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving followers for:%@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ECTwitterUserUpdated object:self];
}

// --------------------------------------------------------------------------
/// Return the user name in the form "Full Name (@twitterName)"
// --------------------------------------------------------------------------

- (NSString*)longDisplayName
{
    NSString* realName = self.name;
    NSString* shortName = self.twitterName;
    NSString* result;
    if (realName)
    {
        result = [NSString stringWithFormat:@"%@ (@%@)", [self name], [self twitterName]];
    }
    else
    {
        result = shortName;
    }

    return result;
}

// --------------------------------------------------------------------------
/// Return the user's "description" field
/// (called "bio" to avoid clash with the standard NSObject description method).
// --------------------------------------------------------------------------

- (NSString*)bio
{
	return (self.data)[@"description"];
}

// --------------------------------------------------------------------------
/// Return an image for the user.
// --------------------------------------------------------------------------

- (ECTwitterImage*)image
{
	ECTwitterImage* image = self.cachedImage;
	if (!image)
	{
		NSURL* url = [NSURL URLWithString:(self.data)[@"profile_image_url"]];
		image = [self.cache imageWithID:self.twitterID URL:url];
		self.cachedImage = image;
	}
	
	return image;
}

// --------------------------------------------------------------------------
/// Save the user to a file.
// --------------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder*)coder
{
    ECDebug(TwitterCacheCodingChannel, @"encoded %@", self);
	NSDictionary* info = self.data;
	if (!info)
	{
		info = @{@"id_str": self.twitterID.string};
	}
	
    [coder encodeObject:info forKey:@"info"];
    [coder encodeObject:self.twitterID forKey:@"id"];
    [coder encodeObject:self.posts forKey:@"posts"];
    [coder encodeObject:self.timeline forKey:@"timeline"];
    [coder encodeObject:self.mentions forKey:@"mentions"];
    [coder encodeObject:self.friends forKey:@"friends"];
    [coder encodeObject:self.followers forKey:@"followers"];
}


// --------------------------------------------------------------------------
/// Modify the favourited state of a tweet.
// --------------------------------------------------------------------------

- (void)setFavouritedStateForTweet:(ECTwitterTweet*)tweet to:(BOOL)state
{
	ECDebug(TwitterUserChannel, @"making favourite:%@", tweet);
	NSString* format = state ? @"favorites/create/%@" :@"favorites/destroy/%@";
    NSString* method = [NSString stringWithFormat:format, tweet.twitterID.string];
	[self.engine callPostMethod:method parameters:nil authentication:self.defaultAuthentication extra:tweet handler:^(ECTwitterHandler* handler) {

        if (handler.status == StatusResults)
        {
            ECAssertIsKindOfClass(handler.result, NSArray);

            NSArray* favourites = handler.result;
            for (NSDictionary* tweetData in favourites)
            {

                ECTwitterTweet* favourite = [self.cache addOrRefreshTweetWithInfo:tweetData];
                ECDebug(TwitterUserChannel, @"made tweet favourite:%@", favourite); ECUnusedInRelease(favourite);
            }
        }

    }];
}

// --------------------------------------------------------------------------
/// If we're an authenticated user, return our information, otherwise
/// return the default authenticated user's information.
// --------------------------------------------------------------------------

- (ECTwitterAuthentication*)defaultAuthentication
{
    ECTwitterAuthentication* result = self.authentication;

    if (!result)
    {
        result = [super defaultAuthentication];
    }

    return result;
}

// --------------------------------------------------------------------------
//! Post a new tweet, possibly in reply to an existing one.
// --------------------------------------------------------------------------

- (void)postText:(NSString*)text inReplyTo:(ECTwitterTweet*)tweet
{
	ECDebug(TwitterUserChannel, @"posting reply:%@ to %@", text, tweet);

	// Convert the status to Unicode Normalized Form C to conform to Twitter's character counting requirement. See http://apiwiki.twitter.com/Counting-Characters .
	NSString* trimmedText = [text precomposedStringWithCanonicalMapping];
	NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       trimmedText, @"status",
                                       @"1", @"trim_user",
                                       nil];
	if (tweet)
	{
		parameters[@"in_reply_to_status_id"] = tweet.twitterID.string;
	}

	[self.engine callPostMethod:@"statuses/update" parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(postHandler:) extra:nil];
}

// --------------------------------------------------------------------------
//! Retweeting an existing tweet.
// --------------------------------------------------------------------------

- (void)retweet:(ECTwitterTweet*)tweet
{
	ECDebug(TwitterUserChannel, @"retweeting @", tweet);

	NSDictionary* parameters = @{@"trim_user": @"1"};
    NSString* method = [NSString stringWithFormat:@"statuses/retweet/%@", tweet.twitterID.string];
	[self.engine callPostMethod:method parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(postHandler:) extra:nil];
}

// --------------------------------------------------------------------------
//! Handle a post or reply.
// --------------------------------------------------------------------------

- (void)postHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		NSDictionary* postData = handler.result;
		ECDebug(TwitterUserChannel, @"posted %@", postData); ECUnusedInRelease(postData);
	}
    else if (handler.status == StatusFailed)
    {
		ECDebug(TwitterUserChannel, @"post failed %@", handler.error);
    }
}

@end
