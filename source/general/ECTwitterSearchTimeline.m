// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterSearchTimeline.h"

#import "ECTwitterCache.h"
#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterEngine.h"
#import "ECTwitterTweet.h"
#import "ECTwitterUserMentionsTimeline.h"
#import "ECTwitterHandler.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterSearchTimeline()

- (void)fetchTweetsMatchingSearch:(NSString*)search;

@end


@implementation ECTwitterSearchTimeline

// ==============================================
// Properties
// ==============================================

#pragma mark - Channels

ECDefineDebugChannel(TwitterSearchTimelineChannel);

#pragma mark - Properties

@synthesize text;

// ==============================================
// Constants
// ==============================================

#pragma mark - Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark - Methods

// --------------------------------------------------------------------------
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
    [text release];
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Refresh this timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    ECAssertNonNil(self.text);
    [self fetchTweetsMatchingSearch:self.text];
}

// --------------------------------------------------------------------------
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void)fetchTweetsMatchingSearch:(NSString*)search
{
    ECDebug(TwitterSearchTimelineChannel, @"requesting timeline for search %@", self.text);
    
    NSString* methodName = @"search";
    NSUInteger count = 100;
    
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       search, @"q",
                                       [NSString stringWithFormat:@"%d", count], @"rpp",
                                       nil];
    
    [self.engine callGetMethod:methodName parameters: parameters target: self selector: @selector(searchHandler:)];
}

- (void) searchHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
        
		ECDebug(TwitterSearchTimelineChannel, @"received timeline for: %@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);
        
        NSArray* results = [handler.result objectForKey:@"results"];
		for (NSDictionary* tweetData in results)
		{
			ECTwitterTweet* tweet = [mCache addOrRefreshTweetWithInfo: tweetData];
			[self addTweet: tweet];
			
			ECDebug(TwitterSearchTimelineChannel, @"tweet info received: %@", tweet);
		}
	}
	else
	{
		ECDebug(TwitterSearchTimelineChannel, @"error receiving search results for: %@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTimelineUpdated object: self];
}

// --------------------------------------------------------------------------
//! Return debug description.
// --------------------------------------------------------------------------

- (NSString*)description
{
    return [NSString stringWithFormat:@"<ECTwitterSearchTimeline: %d tweets for text %@>", [self.tweets count], self.text];
}

@end
