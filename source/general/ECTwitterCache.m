// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterCache.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"
#import "ECTwitterUser.h"
#import "ECTwitterTweet.h"
#import "ECTwitterID.h"

// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterCache()

- (void)	requestUserByID: (ECTwitterID*) userID;
- (void)	userInfoHandler: (ECTwitterHandler*) handler;
- (void)	makeFavouriteHandler: (ECTwitterHandler*) handler;
- (NSURL*)	userCacheFolder;
- (NSURL*)	tweetCacheFolder;
- (NSURL*)	imageCacheFolder;

@end


@implementation ECTwitterCache

// ==============================================
// Debug Channels
// ==============================================

ECDefineDebugChannel(TwitterCacheChannel);

// ==============================================
// Properties
// ==============================================

ECPropertySynthesize(users);
ECPropertySynthesize(tweets);
ECPropertySynthesize(engine);


// ==============================================
// Notifications
// ==============================================

NSString *const ECTwitterUserUpdated = @"UserUpdated";
NSString *const ECTwitterTweetUpdated = @"TweetUpdated";
NSString *const ECTwitterTimelineUpdated = @"TimelineUpdated";

// ==============================================
// Constants
// ==============================================

// ==============================================
// Methods
// ==============================================

- (id) initWithEngine: (ECTwitterEngine*) engine
{
	if ((self = [super init]) != nil)
	{
		self.engine = engine;
		self.tweets = [NSMutableDictionary dictionary];
		self.users = [NSMutableDictionary dictionary];
 	}
	
	return self;
}

- (ECTwitterTweet*) tweetWithID: (ECTwitterID*) tweetID
{
	ECTwitterTweet* tweet = [self.tweets objectForKey: tweetID.string];
	if (!tweet)
	{
		tweet = [[[ECTwitterTweet alloc] initWithID: tweetID inCache: self] autorelease];
		[self.tweets setObject: tweet forKey: tweetID.string];
	}
	
	return tweet;
}

- (ECTwitterUser*) userWithID: (ECTwitterID*) userID
{
	ECTwitterUser* user = [self.users objectForKey: userID.string];
	if (!user)
	{
		user = [[[ECTwitterUser alloc] initWithID: userID inCache: self] autorelease];
		[self.users setObject: user forKey: userID.string];
		[self requestUserByID: userID];
	}
	
	return user;
}

- (ECTwitterTweet*) addOrRefreshTweetWithInfo: (NSDictionary*) info
{
	ECTwitterID* tweetID = [ECTwitterID idFromDictionary: info];
	ECTwitterTweet* tweet = [self.tweets objectForKey: tweetID.string];
	if (!tweet)
	{
		tweet = [[ECTwitterTweet alloc] initWithInfo: info inCache: self];
		[self.tweets setObject: tweet forKey: tweetID.string];
		[tweet release];
	}
	else
	{
		[tweet refreshWithInfo: info];
	}
	
	NSDictionary* authorData = [info objectForKey: @"user"];
	if ([authorData count] > 2)
	{
		[self addOrRefreshUserWithInfo: authorData];
	}

	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTweetUpdated object: tweet];

	return tweet;
}

- (ECTwitterUser*) addOrRefreshUserWithInfo: (NSDictionary*) info
{
	ECTwitterID* userID = [ECTwitterID idFromDictionary: info];
	ECTwitterUser* user = [self.users objectForKey: userID.string];
	if (!user)
	{
		user = [[ECTwitterUser alloc] initWithInfo: info inCache: self];
		[self.users setObject: user forKey: userID.string];
		[user release];
	}
	else
	{
		[user refreshWithInfo: info];
	}
	
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterUserUpdated object: user];

	return user;
}

// --------------------------------------------------------------------------
//! Request info about a given user id
// --------------------------------------------------------------------------

- (void) requestUserByID: (ECTwitterID*) userID
{
	ECDebug(TwitterCacheChannel, @"requesting user info");
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID.string, @"user_id",
								nil];
	[self.engine callGetMethod: @"users/show" parameters: parameters target: self selector: @selector(userInfoHandler:)];
}


// --------------------------------------------------------------------------
//! Modify the favourited state of a tweet.
// --------------------------------------------------------------------------

- (void) setFavouritedStateForTweet: (ECTwitterTweet*) tweet to: (BOOL) state
{
	ECDebug(TwitterCacheChannel, @"making favourite: %@", tweet);
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								nil];
	
	NSString* format = state ? @"favorites/create/%@" : @"favorites/destroy/%@";
	[self.engine callPostMethod: [NSString stringWithFormat: format, tweet.twitterID.string] parameters: parameters target: self selector: @selector(makeFavouriteHandler:) extra: tweet];
	
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) userInfoHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		for (NSDictionary* userData in ((NSArray*) handler.results))
		{
			ECTwitterID* userID = [ECTwitterID idFromDictionary: userData];
			
			ECTwitterUser* user = [self.users objectForKey: userID.string];
			[user refreshWithInfo: userData];
			
			NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
			[nc postNotificationName: ECTwitterUserUpdated object: user];

			ECDebug(TwitterCacheChannel, @"user info received: %@", user.name);
		}
	}
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've made a favourite
// --------------------------------------------------------------------------

- (void) makeFavouriteHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		for (NSDictionary* tweetData in (NSArray*) handler.results)
		{

			ECTwitterTweet* tweet = [self addOrRefreshTweetWithInfo: tweetData];
			ECDebug(TwitterCacheChannel, @"made tweet favourite: %@", tweet); ECUnusedInRelease(tweet);
		}
	}
}

// --------------------------------------------------------------------------
//! Return image for object with a given ID, at a given URL.
//! The image may be cached locally, or may be fetched. 
//! The cached version may be refreshed if it is old.
// --------------------------------------------------------------------------

- (NSImage*) imageWithID: (ECTwitterID*) imageID URL: (NSURL*) url
{
	NSImage* image = [[NSImage alloc] initWithContentsOfURL: url];
	
	return [image autorelease];
}

// --------------------------------------------------------------------------
//! Save current users and tweets to a local cache.
// --------------------------------------------------------------------------

- (void) save
{
	NSURL* cacheFolder = [self userCacheFolder];
	for (ECTwitterUser* user in self.users)
	{
		[user saveTo: cacheFolder];
	}
	
	cacheFolder = [self tweetCacheFolder];
	for (ECTwitterTweet* tweet in self.tweets)
	{
		[tweet saveTo: cacheFolder];
	}
}

// --------------------------------------------------------------------------
//! Load users and tweets from a local cache.
// --------------------------------------------------------------------------

- (void) load
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSError* error = nil;

	NSURL* cacheFolder = [self userCacheFolder];
	NSArray* items = [fm contentsOfDirectoryAtURL: cacheFolder includingPropertiesForKeys: nil options: 0 error: &error];
	if (items && !error)
	{
		for (NSURL* url in items)
		{
			ECTwitterUser* user = [[ECTwitterUser alloc] initWithContentsOfURL: url];
			[self.users setObject: user forKey: user.twitterID.string];
			[user release];
		}
	}

	cacheFolder = [self tweetCacheFolder];
	items = [fm contentsOfDirectoryAtURL: cacheFolder includingPropertiesForKeys: nil options: 0 error: &error];
	if (items && !error)
	{
		for (NSURL* url in items)
		{
			ECTwitterTweet* tweet = [[ECTwitterTweet alloc] initWithContentsOfURL: url];
			[self.tweets setObject: tweet forKey: tweet.twitterID.string];
			[tweet release];
		}
	}
	
}

- (NSURL*) userCacheFolder
{
	return nil;
}

- (NSURL*) tweetCacheFolder
{
	return nil;
}

- (NSURL*) imageCacheFolder
{
	return nil;
}

@end
