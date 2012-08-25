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
		self.twitterID = [ECTwitterID idFromDictionary: dictionary];
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
    
    return self;
}

// --------------------------------------------------------------------------
/// Set up with just an ID.
// --------------------------------------------------------------------------

- (id)initWithID:(ECTwitterID*)idIn inCache:(ECTwitterCache*)cache
{
	if ((self = [super initWithCache: cache]) != nil)
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
    ECTwitterUserTimeline* homeTimeline = [[ECTwitterUserTimeline alloc] initWithCache:mCache];
    homeTimeline.user = self;
    self.timeline = homeTimeline;
    [homeTimeline trackHome];
    [homeTimeline release];
    
    ECTwitterUserTimeline* postsTimeline = [[ECTwitterUserTimeline alloc] initWithCache:mCache];
    postsTimeline.user = self;
    self.posts = postsTimeline;
    [postsTimeline trackPosts];
    [postsTimeline release];
    
    ECTwitterUserMentionsTimeline* mentionsTimeline = [[ECTwitterUserMentionsTimeline alloc] initWithCache:mCache];
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
	return (self.data != nil) && ([self.data objectForKey:@"name"] != nil);
}

// --------------------------------------------------------------------------
/// Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*)description
{
	return [NSString stringWithFormat: @"<TwitterUser: %@ %@ posts:%ld timeline:%ld mentions:%ld>", self.twitterName, self.twitterID, (long) [self.posts count], (long) [self.timeline count], (long) [self.mentions count]];
}

// --------------------------------------------------------------------------
/// Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*)name
{
	return [self.data objectForKey: @"name"];
}

// --------------------------------------------------------------------------
/// Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*)twitterName
{
	return [self.data objectForKey: @"screen_name"];
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

	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"friends/ids" parameters: parameters target: self selector: @selector(followerIDsHandler:) extra:nil];
}

// --------------------------------------------------------------------------
/// Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFollowers
{
	ECDebug(TwitterUserChannel, @"requesting followers for %@", self);
    ECAssertNonNil(self.twitterID.string);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/followers" parameters: parameters target: self selector: @selector(followersHandler:) extra:nil];
}

// --------------------------------------------------------------------------
/// Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFriends
{
	ECDebug(TwitterUserChannel, @"requesting friends for %@", self);
    ECAssertNonNil(self.twitterID.string);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/friends" parameters: parameters target: self selector: @selector(friendsHandler:) extra:nil];
}


// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) friendsHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for: %@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);
        
        NSDictionary* info = handler.result;
        NSArray* users = [info objectForKey:@"users"];
		for (NSDictionary* userData in users)
		{
			ECTwitterUser* user = [mCache addOrRefreshUserWithInfo: userData];
			[self addFriend: user];
			
			ECDebug(TwitterUserChannel, @"friend info received: %@", user);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving friends for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterUserUpdated object: self];
}


// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followersHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for: %@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);

        NSDictionary* result = handler.result;
        NSArray* users = [result objectForKey:@"users"];
		for (NSDictionary* userData in users)
		{
			ECTwitterUser* user = [mCache addOrRefreshUserWithInfo: userData];
			[self addFriend: user];
			
			ECDebug(TwitterUserChannel, @"friend info received: %@", user);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving friends for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterUserUpdated object: self];
}

// --------------------------------------------------------------------------
/// Handle confirmation that we've authenticated ok as a given user.
/// We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followerIDsHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received followers for: %@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);

        NSDictionary* result = handler.result;
        NSArray* userIDs = [result objectForKey:@"ids"];
		for (NSNumber* value in userIDs)
		{
#if 0
            NSString* userIDString = [value stringValue];
            ECTwitterID* userID = [[ECTwitterID alloc] initWithString:userIDString];
            
            ECTwitterUser* user = [mCache userWithID:userID];
			[self addFollower: user];
            [userID release];
			
			ECDebug(TwitterUserChannel, @"follower info received: %@", user);
#endif
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving followers for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterUserUpdated object: self];
}

// --------------------------------------------------------------------------
/// Return the user name in the form "Full Name (@twitterName)"
// --------------------------------------------------------------------------

- (NSString*)longDisplayName
{
	return [NSString stringWithFormat: @"%@ (@%@)", [self name], [self twitterName]];
}

// --------------------------------------------------------------------------
/// Return the user's "description" field
/// (called "bio" to avoid clash with the standard NSObject description method).
// --------------------------------------------------------------------------

- (NSString*)bio
{
	return [self.data objectForKey: @"description"];
}

// --------------------------------------------------------------------------
/// Return an image for the user.
// --------------------------------------------------------------------------

- (ECTwitterImage*)image
{
	ECTwitterImage* image = self.cachedImage;
	if (!image)
	{
		NSURL* url = [NSURL URLWithString:[self.data objectForKey: @"profile_image_url"]];
		image = [mCache imageWithID: self.twitterID URL: url];
		self.cachedImage = image;
	}
	
	return image;
}

// --------------------------------------------------------------------------
/// Save the user to a file.
// --------------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder*)coder
{
	NSDictionary* info = self.data;
	if (!info)
	{
		info = [NSDictionary dictionaryWithObject: self.twitterID.string forKey: @"id_str"];
	}
	
    [coder encodeObject:info forKey:@"info"];
    [coder encodeObject:self.twitterID forKey:@"id"];
    [coder encodeObject:self.posts forKey:@"posts"];
    [coder encodeObject:self.timeline forKey:@"timeline"];
    [coder encodeObject:self.mentions forKey:@"mentions"];
    [coder encodeObject:self.friends forKey:@"friends"];
    [coder encodeObject:self.followers forKey:@"followers"];
}

@end
