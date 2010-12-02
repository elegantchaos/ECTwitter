// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/11/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
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

- (void) requestUserByID: (ECTwitterID*) userID;
- (void) timelineHandler: (ECTwitterHandler*) handler;
- (void) userInfoHandler: (ECTwitterHandler*) handler;
- (void) makeFavouriteHandler: (ECTwitterHandler*) handler;
- (ECTwitterUser*) addOrRefreshUserWithInfo: (NSDictionary*) info;
- (ECTwitterTweet*) addOrRefreshTweetWithInfo: (NSDictionary*) info;

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
		tweet = [[[ECTwitterTweet alloc] initWithID: tweetID] autorelease];
		[self.tweets setObject: tweet forKey: tweetID.string];
	}
	
	return tweet;
}

- (ECTwitterUser*) userWithID: (ECTwitterID*) userID
{
	ECTwitterUser* user = [self.users objectForKey: userID.string];
	if (!user)
	{
		user = [[[ECTwitterUser alloc] initWithID: userID] autorelease];
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
		tweet = [[ECTwitterTweet alloc] initWithInfo: info];
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
		user = [[ECTwitterUser alloc] initWithInfo: info];
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
//! Request user timeline
// --------------------------------------------------------------------------

- (void) requestTimelineForUser:(ECTwitterUser*) user
{
	ECDebug(TwitterCacheChannel, @"requesting timeline for %@", user);
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								user.twitterID.string, @"user_id",
								//@"1", @"trim_user",
								@"50", @"count",
								nil];
	
	[self.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:) extra: user];
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
//! Request user timeline
// --------------------------------------------------------------------------

- (void) refreshTimelineForUser:(ECTwitterUser*) user
{
	ECDebug(TwitterCacheChannel, @"refreshing timeline for %@", user);

	NSString* userID = user.twitterID.string;
	NSString* newestID = user.newestTweet.string;
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID, @"user_id",
								//@"1", @"trim_user",
								@"50", @"count",
								newestID, @"since_id",
								nil];
	
	[self.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:) extra: user];
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
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) timelineHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECTwitterUser* user = (ECTwitterUser*) handler.extra;
		
		for (NSDictionary* tweetData in (NSArray*) handler.results)
		{
			ECTwitterTweet* tweet = [self addOrRefreshTweetWithInfo: tweetData];
			[user addTweet: tweet];
			
			ECDebug(TwitterCacheChannel, @"tweet info received: %@", tweet);
		}
		
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: ECTwitterUserUpdated object: user];
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
			ECDebug(TwitterCacheChannel, @"made tweet favourite: %@", tweet);
		}
	}
}

@end
