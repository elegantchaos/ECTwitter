// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterUser.h"
#import "ECTwitterID.h"
#import "ECTwitterTweet.h"

@implementation ECTwitterUser

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(data);
ECPropertySynthesize(twitterID);
ECPropertySynthesize(tweets);
ECPropertySynthesize(newestTweet);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithUserInfo: (NSDictionary*) dictionary
{
	if ((self = [super init]) != nil)
	{
		self.data = dictionary;
		self.twitterID = [ECTwitterID idFromDictionary: dictionary];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID.
// --------------------------------------------------------------------------

- (id) initWithID: (ECTwitterID*) twitterID
{
	if ((self = [super init]) != nil)
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
	return [self.data description];
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
	
	[tweets insertObject: tweet atIndex: 0];
}

@end
