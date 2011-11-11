// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUserMentionsTimeline.h"

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

@interface ECTwitterUserMentionsTimeline()

@end


@implementation ECTwitterUserMentionsTimeline

// ==============================================
// Properties
// ==============================================

#pragma mark - Channels

ECDefineDebugChannel(TwitterUserMentionsTimelineChannel);

#pragma mark - Properties

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
//! Set up from a coder.
// --------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)coder
{
    ECTwitterCache* cache = [ECTwitterCache decodingCache];
	if ((self = [super initWithCoder:coder]) != nil)
    {
        ECTwitterID* userID = [coder decodeObjectForKey:@"user"];
        self.user = [cache userWithID:userID requestIfMissing:NO];
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

// --------------------------------------------------------------------------
//! Save the timeline to a file.
// --------------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.user.twitterID forKey:@"user"];
    [super encodeWithCoder:coder];
}

// --------------------------------------------------------------------------
//! Refresh this timeline, by refreshing the associated user's main timeline.
// --------------------------------------------------------------------------

- (void)refresh
{
    ECDebug(TwitterUserMentionsTimelineChannel, @"refreshing mentions timeline for user %@", self.user);
    [self fetchTweetsForUser:self.user method:MethodMentions type:FetchLatest];
}

// --------------------------------------------------------------------------
//! Return debug description.
// --------------------------------------------------------------------------

- (NSString*)description
{
    return [NSString stringWithFormat:@"<ECTwitterUserMentionsTimeline: %d tweets>", [self.tweets count]];
}

@end
