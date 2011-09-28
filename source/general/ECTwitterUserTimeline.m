// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUserTimeline.h"

#import "ECTwitterCache.h"
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

@end


@implementation ECTwitterUserTimeline

// ==============================================
// Properties
// ==============================================

#pragma mark - Channels

ECDefineDebugChannel(TwitterUserTimelineChannel);

#pragma mark - Properties

@synthesize method;
@synthesize user;

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
    [user release];
	
	[super dealloc];
}

- (void)trackHome
{
    self.method = MethodHome;
}

- (void)trackPosts
{
    self.method = MethodTimeline;
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
        [self.user.mentions addTweet:tweet];
	}
}

// --------------------------------------------------------------------------
//! Refresh this timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    [self fetchTweetsForUser:self.user method:self.method type:FetchLatest];
}

// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We do the normal thing, but also post an update for the mentions list
//! if it has changed.
// --------------------------------------------------------------------------

- (void) timelineHandler: (ECTwitterHandler*) handler
{
    NSUInteger mentionCount = [self.user.mentions.tweets count];
    
    [super timelineHandler:handler];
    
    if ([self.user.mentions.tweets count] != mentionCount)
    {
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName: ECTwitterTimelineUpdated object:self.user.mentions];
    }
}

// --------------------------------------------------------------------------
//! Return debug description.
// --------------------------------------------------------------------------

- (NSString*)description
{
    return [NSString stringWithFormat:@"<ECTwitterUserTimeline: %d tweets for user %@ type %@>", [self.tweets count], self.user, self.method];
}

@end
