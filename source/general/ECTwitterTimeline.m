// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 24/01/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTimeline.h"
#import "ECTwitterTweet.h"

// ==============================================
// Private Methods
// ==============================================

#pragma mark -
#pragma mark Private Methods

@interface ECTwitterTimeline()

- (ECTwitterTimeline*)	sortedWithSelector: (SEL) selector;

@end


@implementation ECTwitterTimeline

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
	timeline.tweets = [self.tweets mutableCopy];
	[timeline.tweets sortUsingSelector: selector];
	
	return [timeline autorelease];
}

// --------------------------------------------------------------------------
//! Return a copy of this timeline, sorted by date ascending.
// --------------------------------------------------------------------------

- (ECTwitterTimeline*)	sortedByDateAscending
{
	return [self sortedWithSelector: @selector(compareByDateAscending:)];
}

// --------------------------------------------------------------------------
//! Return a copy of this timeline, sorted by date descending.
// --------------------------------------------------------------------------

- (ECTwitterTimeline*)	sortedByDateDescending
{
	return [self sortedWithSelector: @selector(compareByDateDescending:)];
}

// --------------------------------------------------------------------------
//! Return a copy of this timeline, sorted by views and date descending.
// --------------------------------------------------------------------------

- (ECTwitterTimeline*)	sortedByViewsDateDescending
{
	return [self sortedWithSelector: @selector(compareByViewsDateDescending:)];
}


@end
