// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterTweet.h"
#import "ECTwitterCache.h"
#import "ECTwitterHandler.h"
#import "ECTwitterEngine.h"

@interface ECTwitterUser()
- (void) timelineHandler: (ECTwitterHandler*) handler;
@end


@implementation ECTwitterUser

ECDefineDebugChannel(TwitterUserChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(data);
ECPropertySynthesize(twitterID);
ECPropertySynthesize(tweets);
ECPropertySynthesize(newestTweet);
ECPropertySynthesize(cachedImage);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) dictionary inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
		self.data = dictionary;
		self.twitterID = [ECTwitterID idFromDictionary: dictionary];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up from a file.
// --------------------------------------------------------------------------

- (id) initWithContentsOfURL: (NSURL*) url inCache: (ECTwitterCache*) cache
{
	NSDictionary* info = [[NSDictionary alloc] initWithContentsOfURL: url];
	if ((self = [self initWithInfo: info inCache:cache]) != nil)
	{
		
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID.
// --------------------------------------------------------------------------

- (id) initWithID: (ECTwitterID*) twitterID inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
		self.twitterID = twitterID;
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(data);
	ECPropertyDealloc(twitterID);
	ECPropertyDealloc(tweets);
	ECPropertyDealloc(cachedImage);
	
	[super dealloc];
}

// --------------------------------------------------------------------------
//! Update with new info
// --------------------------------------------------------------------------

- (void) refreshWithInfo: (NSDictionary*) info
{
	self.data = info;
}

// --------------------------------------------------------------------------
//! Have we had our data filled in?
// --------------------------------------------------------------------------

- (BOOL) gotData
{
	return (self.data != nil);
}

// --------------------------------------------------------------------------
//! Return debug description of the item.
// --------------------------------------------------------------------------

- (NSString*) description
{
	return [NSString stringWithFormat: @"%@ %@", self.twitterID, self.name];
}

// --------------------------------------------------------------------------
//! Return the proper name of the user.
// --------------------------------------------------------------------------

- (NSString*) name
{
	return [self.data objectForKey: @"name"];
}

// --------------------------------------------------------------------------
//! Return the twitter name of the user.
// --------------------------------------------------------------------------

- (NSString*) twitterName
{
	return [self.data objectForKey: @"screen_name"];
}

// --------------------------------------------------------------------------
//! Add a tweet to our list.
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

	if (!self.newestTweet || ([tweet.twitterID.string compare: self.newestTweet.string] == NSOrderedDescending))
	{
		self.newestTweet = tweet.twitterID;
	}
	
	if ([tweets indexOfObject: tweet] == NSNotFound)
	{
		[tweets addObject: tweet];
	}
}

// --------------------------------------------------------------------------
//! Request user timeline
// --------------------------------------------------------------------------

- (void) requestTimeline
{
	ECDebug(TwitterUserChannel, @"requesting timeline for %@", self);
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								self.twitterID.string, @"user_id",
								//@"1", @"trim_user",
								@"50", @"count",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}


// --------------------------------------------------------------------------
//! Request user timeline
// --------------------------------------------------------------------------

- (void) refreshTimeline
{
	ECDebug(TwitterUserChannel, @"refreshing timeline for %@", self);
	
	NSString* userID = self.twitterID.string;
	NSString* newestID = self.newestTweet.string;
	
	NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								userID, @"user_id",
								//@"1", @"trim_user",
								@"50", @"count",
								newestID, @"since_id",
								nil];
	
	[mCache.engine callGetMethod: @"statuses/home_timeline" parameters: parameters target: self selector: @selector(timelineHandler:)];
}


// --------------------------------------------------------------------------
//! Handle confirmation that we've authenticated ok as a given user.
//! We fire off a request for the list of friends for the user.
// --------------------------------------------------------------------------

- (void) timelineHandler: (ECTwitterHandler*) handler
{
	if (handler.status == StatusResults)
	{
		ECDebug(TwitterUserChannel, @"received timeline for: %@", self);
		for (NSDictionary* tweetData in (NSArray*) handler.results)
		{
			ECTwitterTweet* tweet = [mCache addOrRefreshTweetWithInfo: tweetData];
			[self addTweet: tweet];
			
			ECDebug(TwitterUserChannel, @"tweet info received: %@", tweet);
		}
		
		[self.tweets sortUsingSelector: @selector(compareByViewsDateDescending:)];
		
	}
	else
	{
		ECDebug(TwitterUserChannel, @"error receiving timeline for: %@", self);
	}

	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: ECTwitterTimelineUpdated object: self];
}

// --------------------------------------------------------------------------
//! Return the user name in the form "Full Name (@twitterName)"
// --------------------------------------------------------------------------

- (NSString*) longDisplayName
{
	return [NSString stringWithFormat: @"%@ (@%@)", [self name], [self twitterName]];
}

// --------------------------------------------------------------------------
//! Return the user's "description" field
//! (called "bio" to avoid clash with the standard NSObject description method).
// --------------------------------------------------------------------------

- (NSString*) bio
{
	return [self.data objectForKey: @"description"];
}

// --------------------------------------------------------------------------
//! Return an image for the user.
// --------------------------------------------------------------------------

- (NSImage*) image
{
	NSImage* image = self.cachedImage;
	if (!image)
	{
		NSURL* url = [NSURL URLWithString:[self.data objectForKey: @"profile_image_url"]];
		image = [mCache imageWithID: self.twitterID URL: url];
		self.cachedImage = image;
	}
	
	return image;
}

// --------------------------------------------------------------------------
//! Save the user to a file.
// --------------------------------------------------------------------------

- (void) saveTo: (NSURL*) url
{
	NSDictionary* info = self.data;
	if (!info)
	{
		info = [NSDictionary dictionaryWithObject: self.twitterID.string forKey: @"id_str"];
	}
	
	[info writeToURL: url atomically: YES];
}

@end
