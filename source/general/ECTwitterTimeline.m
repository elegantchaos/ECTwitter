// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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

@synthesize tweets;
@synthesize newestTweet;
@synthesize oldestTweet;

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

- (id) initWithCache:(ECTwitterCache *)cache
{
	if ((self = [super initWithCache:cache]) != nil)
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
	if ((self = [super initWithCache:cache]) != nil)
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
	[tweets release];
	[newestTweet release];
	[oldestTweet release];
	
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
	NSMutableArray* array = self.tweets;
	if (!array)
	{
		array = [[NSMutableArray alloc] initWithCapacity: 1];
		self.tweets = array;
		[array release];
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
	
	if ([array indexOfObject:tweet] == NSNotFound)
	{
		[array addObject:tweet];
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
        
        NSArray* results = handler.result;
		for (NSDictionary* tweetData in results)
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

// --------------------------------------------------------------------------
//! Remove any tweets that we don't have data for from this list.
// --------------------------------------------------------------------------

- (void)removeMissingTweets
{
    NSUInteger n = [self.tweets count];
    while(n--)
    {
        ECTwitterTweet* tweet = [self.tweets objectAtIndex:n];
        if (![tweet gotData])
        {
            [self.tweets removeObjectAtIndex:n];
        }
    }
}

@end
