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

- (void) userInfoHandler: (ECTwitterHandler*) handler;
- (void) requestUserByID: (ECTwitterID*) userID;

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

// --------------------------------------------------------------------------
//! Request info about a given user id
// --------------------------------------------------------------------------

- (void) requestUserByID: (ECTwitterID*) userID
{
	ECDebug(TwitterCacheChannel, @"requesting user info");
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID.string, @"user_id",
								nil];
	[self.engine callMethod: @"users/show" parameters: parameters target: self selector: @selector(userInfoHandler:)];
}


// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) userInfoHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterCacheChannel, @"user info received: %@", handler.results);
		NSDictionary* userData = [((NSArray*) handler.results) objectAtIndex: 0];
		ECTwitterID* userID = [ECTwitterID idFromDictionary: userData];
		
		ECTwitterUser* user = [self.users objectForKey: userID.string];
		[user refreshWithInfo: userData];
		[[NSNotificationCenter defaultCenter] postNotificationName: ECTwitterUserUpdated object: user];
	}
}

@end
