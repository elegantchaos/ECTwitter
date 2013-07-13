// --------------------------------------------------------------------------
//  Copyright 2013 Sam Deane, Elegant Chaos. All rights reserved.
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

@property (strong, nonatomic) ECTwitterID* maxID;

- (void)fetchTweetsMatchingSearch:(NSString*)search;

@end


@implementation ECTwitterSearchTimeline


#pragma mark - Channels

ECDefineDebugChannel(TwitterSearchTimelineChannel);

// ==============================================
// Properties
// ==============================================

#pragma mark - Properties

@synthesize text = _text;
@synthesize maxID = _maxID;

// ==============================================
// Constants
// ==============================================

#pragma mark - Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark - Methods

// --------------------------------------------------------------------------
/// Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
    [_maxID release];
    [_text release];
	
	[super dealloc];
}

// --------------------------------------------------------------------------
/// Refresh this timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    ECAssertNonNil(self.text);
    [self fetchTweetsMatchingSearch:self.text];
}

// --------------------------------------------------------------------------
/// Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void)fetchTweetsMatchingSearch:(NSString*)search
{
    ECDebug(TwitterSearchTimelineChannel, @"requesting timeline for search %@", self.text);
    
    NSString* methodName = @"search/tweets";
    NSUInteger count = 100;
    
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       search, @"q",
                                       [NSString stringWithFormat:@"%ld", (long) count], @"rpp",
                                       nil];
    
    if (self.maxID)
    {
        parameters[@"since_id"] = self.maxID.string;
    }
    
    [self.engine callGetMethod:methodName parameters:parameters authentication:self.defaultAuthentication target:self selector:@selector(searchHandler:) extra:nil];
}

- (void) searchHandler:(ECTwitterHandler*)handler
{
	if (handler.status == StatusResults)
	{
        
		ECDebug(TwitterSearchTimelineChannel, @"received timeline for:%@", self);
        ECAssertIsKindOfClass(handler.result, NSDictionary);
        
        NSDictionary* result = handler.result;
        if (result)
        {
            NSDictionary* meta = result[@"search_metadata"];
            self.maxID = [ECTwitterID idFromKey:@"max_id_str" dictionary:meta];

            NSArray* results = result[@"statuses"];
            for (NSDictionary* tweetData in results)
            {
                ECTwitterTweet* tweet = [self.cache addOrRefreshTweetWithInfo:tweetData];
                [self addTweet:tweet];

                ECDebug(TwitterSearchTimelineChannel, @"tweet info received:%@", tweet);
            }
        }
	}
	else
	{
		ECDebug(TwitterSearchTimelineChannel, @"error receiving search results for:%@", self);
	}
    
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:ECTwitterTimelineUpdated object:self];
}

// --------------------------------------------------------------------------
/// Return debug description.
// --------------------------------------------------------------------------

- (NSString*)description
{
    return [NSString stringWithFormat:@"<ECTwitterSearchTimeline:%ld tweets for text %@>", (long) [self.tweets count], self.text];
}

@end
