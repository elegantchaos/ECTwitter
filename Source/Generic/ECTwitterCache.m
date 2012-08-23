// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterCache.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"
#import "ECTwitterUser.h"
#import "ECTwitterTweet.h"
#import "ECTwitterID.h"
#import "ECTwitterTimeline.h"
#import "ECTwitterUserMentionsTimeline.h"
#import "ECTwitterImage.h"


// --------------------------------------------------------------------------
// Private Methods
// --------------------------------------------------------------------------

@interface ECTwitterCache()

@property (nonatomic, assign) NSUInteger maxCached;

- (void)requestUserByID:(ECTwitterID*)userID;
- (void)userInfoHandler:(ECTwitterHandler*)handler;
- (void)makeFavouriteHandler:(ECTwitterHandler*)handler;

- (NSURL*)baseCacheFolder;
- (NSURL*)mainCacheFile;
- (NSURL*)imageCacheFolder;

@end


@implementation ECTwitterCache

// ==============================================
// Debug Channels
// ==============================================

ECDefineDebugChannel(TwitterCacheChannel);

// ==============================================
// Properties
// ==============================================

@synthesize authenticated = _authenticated;
@synthesize engine = _engine;
@synthesize maxCached = _maxCached;
@synthesize tweets = _tweets;
@synthesize users = _users;

// ==============================================
// Notifications
// ==============================================

NSString *const ECTwitterUserUpdated = @"UserUpdated";
NSString *const ECTwitterTweetUpdated = @"TweetUpdated";
NSString *const ECTwitterTimelineUpdated = @"TimelineUpdated";

// ==============================================
// Globals
// ==============================================

static ECTwitterCache* gDecodingCache = nil;

// ==============================================
// Constants
// ==============================================

// ==============================================
// Methods
// ==============================================

- (id) initWithEngine:(ECTwitterEngine*)engineIn
{
	if ((self = [super init]) != nil)
	{
		self.engine = engineIn;
		self.tweets = [NSMutableDictionary dictionary];
		self.users = [NSMutableDictionary dictionary];
		self.authenticated = [NSMutableDictionary dictionary];
        self.maxCached = 100; // temporary
 	}
	
	return self;
}

- (void)dealloc 
{
    [_authenticated release];
    [_engine release];
    [_tweets release];
    [_users release];
    
    [super dealloc];
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
    return [self userWithID:userID requestIfMissing:YES];
}

- (ECTwitterUser*)userWithID:(ECTwitterID *)userID requestIfMissing:(BOOL)requestIfMissing
{
    if ((userID == nil) || (userID.string == nil))
    {
        NSLog(@"nil userID or userID.string found");
    }
    ECAssertNonNil(userID);
    ECAssertNonNil(userID.string);
    
	ECTwitterUser* user = [self.users objectForKey: userID.string];
	if (!user)
	{
		user = [[[ECTwitterUser alloc] initWithID: userID inCache: self] autorelease];
		[self.users setObject: user forKey: userID.string];
        if (requestIfMissing)
        {
            [self requestUserByID: userID];
        }
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
    ECAssertNonNil(userID.string);
	
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
        ECAssertIsKindOfClass(handler.result, NSDictionary);

        NSDictionary* userData = handler.result;
        ECTwitterID* userID = [ECTwitterID idFromDictionary: userData];
        
        ECTwitterUser* user = [self.users objectForKey: userID.string];
        [user refreshWithInfo: userData];
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: ECTwitterUserUpdated object: user];

        ECDebug(TwitterCacheChannel, @"user info received: %@", user.name);
	}
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've made a favourite
// --------------------------------------------------------------------------

- (void) makeFavouriteHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
        ECAssertIsKindOfClass(handler.result, NSArray);

        NSArray* favourites = handler.result;
		for (NSDictionary* tweetData in favourites)
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

- (ECTwitterImage*) imageWithID: (ECTwitterID*) imageID URL: (NSURL*) url
{
	ECTwitterImage* image = [[ECTwitterImage alloc] initWithContentsOfURL: url];
	
	return [image autorelease];
}

// --------------------------------------------------------------------------
//! Restoring from the cache can leave us with some tweets that have no data
//! because references to them were in timelines that were restored, even though
//! the timelines themselves weren't.
//!
//! This method cleans up all the timelines and removes these tweets.
// --------------------------------------------------------------------------

- (void)removeMissingTweets
{
    NSArray* allUsers = [self.users allValues];
    for (ECTwitterUser* user in allUsers)
    {
        [user.mentions removeMissingTweets];
        [user.posts removeMissingTweets];
        [user.timeline removeMissingTweets];
    }
    
    NSArray* allTweets = [self.tweets allValues];
    NSUInteger n = [allTweets count];
    while (n--)
    {
        ECTwitterTweet* tweet = [allTweets objectAtIndex:0];
        if (![tweet gotData])
        {
            [self.tweets removeObjectForKey:tweet.twitterID.string];
        }
    }

}
// --------------------------------------------------------------------------
//! Save current users and tweets to a local cache.
// --------------------------------------------------------------------------

- (void) save
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

    [archiver encodeObject:self.users forKey:@"users"];

    // save recent tweets
    NSArray* allTweets = [self.tweets allValues];
    NSArray* sortedTweets = [allTweets sortedArrayUsingSelector:@selector(compareByViewsDateDescending:)];
    NSUInteger count = [sortedTweets count];
    count = MIN(count, self.maxCached);
    NSMutableDictionary* recentTweets = [NSMutableDictionary dictionaryWithCapacity:count];
    for (ECTwitterTweet* tweet in sortedTweets)
    {
        [recentTweets setObject:tweet forKey:tweet.twitterID.string];
        if (--count == 0)
        {
            break;
        }
    }

    // save mentions of authenticated users
    for (ECTwitterUser* user in [self.authenticated allValues])
    {
        NSArray* mentions = user.mentions.tweets;
        for (ECTwitterTweet* tweet in mentions)
        {
            [recentTweets setObject:tweet forKey:tweet.twitterID.string];
        }
    }
    
    [archiver encodeObject:recentTweets forKey:@"tweets"];
    [archiver finishEncoding];
    
    NSURL* url = [self mainCacheFile];
	BOOL ok = [data writeToURL:url atomically:YES];
    if (!ok)
    {
		ECDebug(TwitterCacheChannel, @"failed to write cache to %@", url);
    }
    
    [archiver release];
    [data release];

}

// --------------------------------------------------------------------------
//! Load users and tweets from a local cache.
// --------------------------------------------------------------------------

- (void) load
{
    NSURL* url = [self mainCacheFile];
    NSData* data = [NSData dataWithContentsOfURL:url];
    if (data)
    {
        NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        // unarchive the users & tweets
        // just loading them in is enough to add them to the cache,
        // so we don't actually have to do anything with the result of the decode calls
        @synchronized(self)
        {
            gDecodingCache = self;
            [unarchiver decodeObjectForKey:@"users"];
            [unarchiver decodeObjectForKey:@"tweets"];
            gDecodingCache = nil;
        }
        
        [unarchiver release];
        
        [self removeMissingTweets];
        
        ECDebug(TwitterCacheChannel, @"loaded cached users %@", self.users);
        ECDebug(TwitterCacheChannel, @"loaded cached tweets %@", self.tweets);
    }
}

// --------------------------------------------------------------------------
//! Return the current decoding cache - used to provide some context
//! when decoding cached objects.
// --------------------------------------------------------------------------

+ (ECTwitterCache*)decodingCache
{
    return gDecodingCache;
}

// --------------------------------------------------------------------------
//! Return the base cached folder for the app.
// --------------------------------------------------------------------------

- (NSURL*)baseCacheFolder
{
    NSArray* urls = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* root = [urls objectAtIndex:0];
    NSURL* url = [root URLByAppendingPathComponent:@"com.elegantchaos.ambientweet"];

    return url;
}


// --------------------------------------------------------------------------
//! Return the path to the main cache file.
// --------------------------------------------------------------------------

- (NSURL*) mainCacheFile
{
    NSURL* root = [self baseCacheFolder];
    NSURL* url = [root URLByAppendingPathComponent:@"ECTwitterEngine Cache V5.cache"];
    
	return url;
}

// --------------------------------------------------------------------------
//! Return the path to the image cache folder.
// --------------------------------------------------------------------------

- (NSURL*) imageCacheFolder
{
    NSURL* url = [[self baseCacheFolder] URLByAppendingPathComponent:@"Images"];

    NSError* error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];

	return url;
}

@end