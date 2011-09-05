// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUserTimeline.h"
#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterEngine.h"
#import "ECTwitterTweet.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterUserTimeline()

- (void)requestTimeline;
- (void)refreshTimeline;

@end


@implementation ECTwitterUserTimeline

// ==============================================
// Properties
// ==============================================

#pragma mark - Channels

ECDefineDebugChannel(TwitterUserTimelineChannel);

#pragma mark - Properties

ECPropertySynthesize(user);

// ==============================================
// Constants
// ==============================================

#pragma mark - Constants

// ==============================================
// Lifecycle
// ==============================================

#pragma mark - Methods

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
//! Clean up and release retained objects.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(user);
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Add a tweet to our timeline.
//! If the tweet refers to our user, we also add it to that user's mentions
//! timeline.
// --------------------------------------------------------------------------

- (void)addTweet: (ECTwitterTweet*) tweet;
{
    [super addTweet:tweet];
    
    if ([tweet mentionsUser:self.user])
	{
		ECTwitterTimeline* mentions = self.user.mentions;
		if (!mentions)
		{
			mentions = [[ECTwitterTimeline alloc] init];
			self.user.mentions = mentions;
			[mentions release];
		}
		
		[mentions addTweet: tweet];
	}
}

// --------------------------------------------------------------------------
//! Refresh this timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    if ([self.tweets count])
    {
        [self refreshTimeline];
    }
    else
    {
        [self requestTimeline];
    }
}
         
// --------------------------------------------------------------------------
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void) requestTimeline
{
    ECDebug(TwitterUserTimelineChannel, @"requesting timeline for %@", self.user);
    
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.user.twitterID.string, @"user_id",
                                @"1", @"trim_user",
                                @"200", @"count",
                                nil];
    
    [self.user.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}


// --------------------------------------------------------------------------
//! Request user timeline - everything they've received
// --------------------------------------------------------------------------

- (void) refreshTimeline
{
    ECDebug(TwitterUserTimelineChannel, @"refreshing timeline for %@", self.user);
    
    NSString* userID = self.user.twitterID.string;
    NSString* newestID = self.newestTweet.twitterID.string;
    
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                userID, @"user_id",
                                @"1", @"trim_user",
                                @"200", @"count",
                                newestID, @"since_id",
                                nil];
    
    [self.user.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}

@end
