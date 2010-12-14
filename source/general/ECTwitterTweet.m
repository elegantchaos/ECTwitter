// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTweet.h"
#import "ECTwitterID.h"
#import "ECTwitterCache.h"

@implementation ECTwitterTweet

ECDefineDebugChannel(TweetChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(data);
ECPropertySynthesize(cachedAuthor);
ECPropertySynthesize(twitterID);
ECPropertySynthesize(authorID);
ECPropertySynthesize(viewed);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
		self.data = info;
		NSDictionary* authorInfo = [info objectForKey: @"user"];
		
		self.twitterID = [ECTwitterID idFromDictionary: info];
		self.authorID = [ECTwitterID idFromDictionary: authorInfo];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID
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
//! Update the tweet data.
// --------------------------------------------------------------------------

- (void) refreshWithInfo:(NSDictionary *)info
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
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(data);
	ECPropertyDealloc(authorID);
	ECPropertyDealloc(twitterID);
	ECPropertyDealloc(cachedAuthor);
	
	[super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"%@ %@", self.twitterID, self.text];
}

- (NSString*) text
{
	return [self.data objectForKey: @"text"];
}

//- (NSString*) source
//{
//	return [self.user objectForKey: @"source"];
//}

- (BOOL) gotLocation
{
	return [self.data objectForKey: @"geo"] || [self.data objectForKey: @"coordinate"];
}

- (BOOL) isFavourited
{
	NSNumber* value = [self.data objectForKey: @"favorited"];
	return [value boolValue];
}

//- (NSString*) locationText
//{
//	NSString* text = [self.user objectForKey: @"location"];
//	
//	return text;
//}

- (CLLocation*) location
{
	CLLocation* result = nil;
	
	id value = [self.data objectForKey: @"geo"];
	if (value && (value != [NSNull null]))
	{
		value = [(NSDictionary*) value objectForKey: @"coordinates"];
	}
	else
	{
		value = [self.data objectForKey: @"coordinate"];
	}
	
	if (value && (value != [NSNull null]))
	{
		NSArray* items;
		if ([value isKindOfClass: [NSString class]])
		{
			NSString* string = value;
			items = [string componentsSeparatedByString: @" "];
		}
		else
		{
			items = value;
		}

		CLLocationDegrees latitude = [[items objectAtIndex: 0] doubleValue];
		CLLocationDegrees longitude = [[items objectAtIndex: 1] doubleValue];
		result = [[[CLLocation alloc] initWithLatitude: latitude longitude: longitude] autorelease];
	}
	
	return result;
}

- (NSDate*) created
{
	NSDate* date;
	id value = [self.data objectForKey: @"created_at"];
	if ([value isKindOfClass: [NSString class]])
	{
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"EEE MM dd HH:mm:ss ZZZ yyyy"];
		date = [formatter dateFromString: value];
		[formatter release];
		ECDebug(TweetChannel, @"converted date %@ from string %@", date, value);
	}
	else if ([value isKindOfClass: [NSNumber class]])
	{
		date = [NSDate dateWithTimeIntervalSince1970: [value unsignedIntegerValue]];
	}
	else
	{
		date = value;
	}

	
	return date;
}

- (ECTwitterUser*) author
{
	ECTwitterUser* author = self.cachedAuthor;
	
	if (author == nil)
	{
		author = [mCache userWithID: self.authorID];
		self.cachedAuthor = author;
	}
	
	return author;
}
@end
