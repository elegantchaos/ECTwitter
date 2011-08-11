// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterTweet.h"
#import "ECTwitterCache.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"
#import "ECTwitterTimeline.h"
#import "ECTwitterUserList.h"

@interface ECTwitterUser()
- (void) timelineHandler: (ECTwitterHandler*) handler;
- (void) friendsHandler: (ECTwitterHandler*) handler;
- (void) followersHandler: (ECTwitterHandler*) handler;
- (void) followerIDsHandler: (ECTwitterHandler*) handler;
@end


@implementation ECTwitterUser

ECDefineDebugChannel(TwitterUserChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(cachedImage);
ECPropertySynthesize(data);
ECPropertySynthesize(followers);
ECPropertySynthesize(friends);
ECPropertySynthesize(mentions);
ECPropertySynthesize(posts);
ECPropertySynthesize(timeline);
ECPropertySynthesize(twitterID);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) dictionary inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
		self.data = dictionary;
		self.twitterID = [ECTwitterID idFromDictionary: dictionary];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up from a file.
// --------------------------------------------------------------------------

- (id) initWithContentsOfURL: (NSURL*) url inCache: (ECTwitterCache*) cache
{
	NSDictionary* info = [[NSDictionary alloc] initWithContentsOfURL: url];
	if ((self = [self initWithInfo: info inCache:cache]) != nil)
	{
		
	}
	[info release];
    
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID.
// --------------------------------------------------------------------------

- (id) initWithID: (ECTwitterID*) twitterID inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
		self.twitterID = twitterID;
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(cachedImage);
	ECPropertyDealloc(data);
	ECPropertyDealloc(followers);
	ECPropertyDealloc(friends);
	ECPropertyDealloc(mentions);
	ECPropertyDealloc(posts);
	ECPropertyDealloc(timeline);
	ECPropertyDealloc(twitterID);
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Update with new info
// --------------------------------------------------------------------------

- (void) refreshWithInfo: (NSDictionary*) info
{
	self.data = info;
}

// --------------------------------------------------------------------------
//! Have we had our data filled in?
// --------------------------------------------------------------------------

- (BOOL) gotData
{
	return (self.data != nil);
}

// --------------------------------------------------------------------------
//! Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*) description
{
	return [NSString stringWithFormat: @"%@ %@", self.twitterID, self.name];
}

// --------------------------------------------------------------------------
//! Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*) name
{
	return [self.data objectForKey: @"name"];
}

// --------------------------------------------------------------------------
//! Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*) twitterName
{
	return [self.data objectForKey: @"screen_name"];
}

// --------------------------------------------------------------------------
//! Add a tweet to our timeline.
// --------------------------------------------------------------------------

- (void) addTweet: (ECTwitterTweet*) tweet;
{
	ECTwitterTimeline* timeline = self.timeline;
	if (!timeline)
	{
		timeline = [[ECTwitterTimeline alloc] init];
		self.timeline = timeline;
		[timeline release];
	}
	
	[timeline addTweet: tweet];

	if ([tweet mentionsUser: self])
	{
		ECTwitterTimeline* mentions = self.mentions;
		if (!mentions)
		{
			mentions = [[ECTwitterTimeline alloc] init];
			self.mentions = mentions;
			[mentions release];
		}
		
		[mentions addTweet: tweet];
	}
	
}

// --------------------------------------------------------------------------
//! Add a tweet to our posts list.
// --------------------------------------------------------------------------

- (void) addPost: (ECTwitterTweet*) tweet;
{
	ECTwitterTimeline* timeline = self.posts;
	if (!timeline)
	{
		timeline = [[ECTwitterTimeline alloc] init];
		self.posts = timeline;
		[timeline release];
	}
	
	[timeline addTweet: tweet];
}

// --------------------------------------------------------------------------
//! Add a tweet to our posts list.
// --------------------------------------------------------------------------

- (void) addFriend: (ECTwitterUser*) user
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
//! Add a tweet to our posts list.
// --------------------------------------------------------------------------

- (void) addFollower: (ECTwitterUser*) user
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
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void) requestTimeline
{
	ECDebug(TwitterUserChannel, @"requesting timeline for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"1", @"trim_user",
								@"200", @"count",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}


// --------------------------------------------------------------------------
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void) refreshTimeline
{
	ECDebug(TwitterUserChannel, @"refreshing timeline for %@", self);
	
	NSString* userID = self.twitterID.string;
	NSString* newestID = self.timeline.newestTweet.twitterID.string;
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID, @"user_id",
								@"1", @"trim_user",
								@"200", @"count",
								newestID, @"since_id",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}

// --------------------------------------------------------------------------
//! Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestPosts
{
	ECDebug(TwitterUserChannel, @"requesting posts for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"1", @"trim_user",
                                @"1", @"include_rts",
								@"200", @"count",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/user_timeline" parameters: parameters target: self selector: @selector(postsHandler:)];
}


// --------------------------------------------------------------------------
//! Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) refreshPosts
{
	ECDebug(TwitterUserChannel, @"refreshing posts for %@", self);
	
	NSString* userID = self.twitterID.string;
	NSString* newestID = self.posts.newestTweet.twitterID.string;
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID, @"user_id",
								@"1", @"trim_user",
                                @"1", @"include_rts",
								@"200", @"count",
								newestID, @"since_id",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/user_timeline" parameters: parameters target: self selector: @selector(postsHandler:)];
}


// --------------------------------------------------------------------------
//! Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFollowerIDs
{
	ECDebug(TwitterUserChannel, @"requesting followers for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"friends/ids" parameters: parameters target: self selector: @selector(followerIDsHandler:)];
}

// --------------------------------------------------------------------------
//! Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFollowers
{
	ECDebug(TwitterUserChannel, @"requesting followers for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/followers" parameters: parameters target: self selector: @selector(followersHandler:)];
}

// --------------------------------------------------------------------------
//! Request user posts - everything they've posted
// --------------------------------------------------------------------------

- (void) requestFriends
{
	ECDebug(TwitterUserChannel, @"requesting friends for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								@"-1", @"cursor",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/friends" parameters: parameters target: self selector: @selector(friendsHandler:)];
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) timelineHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received timeline for: %@", self);
        NSArray* tweets = handler.result;
		for (NSDictionary* tweetData in tweets)
		{
			ECTwitterTweet* tweet = [mCache addOrRefreshTweetWithInfo: tweetData];
			[self addTweet: tweet];
			
			ECDebug(TwitterUserChannel, @"tweet info received: %@", tweet);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving timeline for: %@", self);
	}

	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTimelineUpdated object: self];
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) postsHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received posts for: %@", self);
        NSArray* tweets = handler.result;
		for (NSDictionary* tweetData in tweets)
		{
			ECTwitterTweet* tweet = [mCache addOrRefreshTweetWithInfo: tweetData];
			[self addPost: tweet];
			
			ECDebug(TwitterUserChannel, @"tweet info received: %@", tweet);
		}
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving posts for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTimelineUpdated object: self];
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) friendsHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for: %@", self);
        NSArray* users = handler.result;
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
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followersHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received friends for: %@", self);
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
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) followerIDsHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received followers for: %@", self);
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
//! Return the user name in the form "Full Name (@twitterName)"
// --------------------------------------------------------------------------

- (NSString*) longDisplayName
{
	return [NSString stringWithFormat: @"%@ (@%@)", [self name], [self twitterName]];
}

// --------------------------------------------------------------------------
//! Return the user's "description" field
//! (called "bio" to avoid clash with the standard NSObject description method).
// --------------------------------------------------------------------------

- (NSString*) bio
{
	return [self.data objectForKey: @"description"];
}

// --------------------------------------------------------------------------
//! Return an image for the user.
// --------------------------------------------------------------------------

- (NSImage*) image
{
	NSImage* image = self.cachedImage;
	if (!image)
	{
		NSURL* url = [NSURL URLWithString:[self.data objectForKey: @"profile_image_url"]];
		image = [mCache imageWithID: self.twitterID URL: url];
		self.cachedImage = image;
	}
	
	return image;
}

// --------------------------------------------------------------------------
//! Save the user to a file.
// --------------------------------------------------------------------------

- (void) saveTo: (NSURL*) url
{
	NSDictionary* info = self.data;
	if (!info)
	{
		info = [NSDictionary dictionaryWithObject: self.twitterID.string forKey: @"id_str"];
	}
	
	[info writeToURL: url atomically: YES];
}

@end
