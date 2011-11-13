// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"
#import "ECTwitterTweet.h"
#import "ECTwitterHandler.h"
#import "ECTwitterCache.h"
#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterEngine.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterTimeline()

@end


@implementation ECTwitterTimeline

#pragma mark - Channels

ECDefineDebugChannel(TwitterTimelineChannel);

// ==============================================
// Properties
// ==============================================

#pragma mark -
#pragma mark Properties

ECPropertySynthesize(tweets);
ECPropertySynthesize(newestTweet);
ECPropertySynthesize(oldestTweet);

// ==============================================
// Constants
// ==============================================

#pragma mark -
#pragma mark Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark -
#pragma mark Methods

// --------------------------------------------------------------------------
//! Set up the object.
// --------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]) != nil)
	{
		
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up from a coder.
// --------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)coder
{
    ECTwitterCache* cache = [ECTwitterCache decodingCache];
	if ((self = [super init]) != nil)
    {
        NSArray* tweetIds = [coder decodeObjectForKey:@"tweets"];
        NSMutableArray* cachedTweets = [NSMutableArray arrayWithCapacity:[tweetIds count]];
        for (ECTwitterID* tweetId in tweetIds)
        {
            [cachedTweets addObject:[cache tweetWithID:tweetId]];
        }

        ECTwitterID* oldestId = [coder decodeObjectForKey:@"oldest"];
        if (oldestId)
        {
            self.oldestTweet = [cache tweetWithID:oldestId];
        }
        
        ECTwitterID* newestId = [coder decodeObjectForKey:@"newest"];
        if (newestId)
        {
            self.newestTweet = [cache tweetWithID:newestId];
        }
        self.tweets = cachedTweets;
    }
    
    return self;
}

// --------------------------------------------------------------------------
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(tweets);
	ECPropertyDealloc(newestTweet);
	ECPropertyDealloc(oldestTweet);
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Save the timeline to a file.
// --------------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder*)coder
{
    NSMutableArray* tweetIds = [NSMutableArray arrayWithCapacity:[self.tweets count]];
    for (ECTwitterTweet* tweet in self.tweets)
    {
        [tweetIds addObject:tweet.twitterID];
    }
    [coder encodeObject:tweetIds forKey:@"tweets"];
    [coder encodeObject:self.oldestTweet.twitterID forKey:@"oldest"];
    [coder encodeObject:self.newestTweet.twitterID forKey:@"newest"];
}

// --------------------------------------------------------------------------
//! Refresh timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    ECDebug(TwitterTimelineChannel, @"don't know how to refresh a plain timeline");
}

// --------------------------------------------------------------------------
//! Add a tweet to our timeline.
// --------------------------------------------------------------------------

- (void) addTweet: (ECTwitterTweet*) tweet;
{
	NSMutableArray* tweets = self.tweets;
	if (!tweets)
	{
		tweets = [[NSMutableArray alloc] initWithCapacity: 1];
		self.tweets = tweets;
		[tweets release];
	}
	
	NSDate* tweetDate = [tweet created];
	if (!self.newestTweet || ([tweetDate compare: self.newestTweet.created] == NSOrderedDescending))
	{
		self.newestTweet = tweet;
	}
	
	if (!self.oldestTweet || ([tweetDate compare: self.oldestTweet.created] == NSOrderedDescending))
	{
		self.oldestTweet = tweet;
	}
	
	if ([tweets indexOfObject: tweet] == NSNotFound)
	{
		[tweets addObject: tweet];
	}
}

// --------------------------------------------------------------------------
//! Return a new, sorted version of this timeline.
// --------------------------------------------------------------------------

- (ECTwitterTimeline*)	sortedWithSelector: (SEL) selector
{
	ECTwitterTimeline* timeline = [[ECTwitterTimeline alloc] init];
	timeline.newestTweet = self.newestTweet;
	timeline.oldestTweet = self.oldestTweet;
    NSMutableArray* tweetsCopy = [self.tweets mutableCopy];
	timeline.tweets = tweetsCopy;
	[timeline.tweets sortUsingSelector: selector];
	[tweetsCopy release];
    
	return [timeline autorelease];
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) timelineHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterTimelineChannel, @"received timeline for: %@", self);
        ECAssertIsKindOfClass(handler.result, NSArray);
        
        NSArray* tweets = handler.result;

		for (NSDictionary* tweetData in tweets)
		{
			ECTwitterTweet* tweet = [mCache addOrRefreshTweetWithInfo: tweetData];
			[self addTweet: tweet];
			
			ECDebug(TwitterTimelineChannel, @"tweet info received: %@", tweet);
		}
	}
	else
	{
		ECDebug(TwitterTimelineChannel, @"error receiving timeline for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTimelineUpdated object: self];
}


// --------------------------------------------------------------------------
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void)fetchTweetsForUser:(ECTwitterUser*)user method:(FetchMethod)method type:(FetchType)type
{
    ECDebug(TwitterTimelineChannel, @"requesting timeline for %@", user);
    
    NSString* methodName;
    NSUInteger count = 200;
    switch (method)
    {
        case MethodMentions:
            methodName = @"statuses/mentions";
            count = 10;
            break;
            
        case MethodHome:
            methodName = @"statuses/home_timeline";
            break;
            
        case MethodTimeline:
            methodName = @"statuses/user_timeline";
            break;
    }

    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                @"1", @"trim_user",
                                @"1", @"include_rts",
                                [NSString stringWithFormat:@"%d", count], @"count",
                                nil];
    
    if (method != MethodMentions)
    {
        ECAssertNonNil(user.twitterID.string);
        [parameters setObject:user.twitterID.string forKey:@"user_id"];
    }
    
    if ((type == FetchLatest) && ([self.tweets count] > 0))
    {
        [parameters setObject:self.newestTweet.twitterID.string forKey:@"since_id"];
    }
    else if (type == FetchOlder)
    {
        [parameters setObject:self.oldestTweet.twitterID.string forKey:@"max_id"];
    }
         
    [user.engine callGetMethod:methodName parameters: parameters target: self selector: @selector(timelineHandler:)];
}

// --------------------------------------------------------------------------
//! Return debug description.
// --------------------------------------------------------------------------

- (NSString*)description
{
    return [NSString stringWithFormat:@"<ECTwitterTimeline: %d tweets>", [self.tweets count]];
}

// --------------------------------------------------------------------------
//! Return the number of tweets in this timeline.
// --------------------------------------------------------------------------

- (NSUInteger)count
{
    return [self.tweets count];
}
@end
