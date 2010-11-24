// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterTweet.h"


@implementation ECTwitterTweet

ECDefineDebugChannel(TweetChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

ECPropertySynthesize(data);
ECPropertySynthesize(user);

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithDictionary: (NSDictionary*) dictionary
{
	if ((self = [super init]) != nil)
	{
		self.data = dictionary;
		self.user = [dictionary objectForKey: @"user"];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Release references.
// --------------------------------------------------------------------------

- (void) dealloc
{
	ECPropertyDealloc(data);
	
	[super dealloc];
}

- (NSString*) description
{
	return [self.data description];
}

- (NSString*) text
{
	return [self.data objectForKey: @"text"];
}

- (NSString*) source
{
	return [self.user objectForKey: @"source"];
}

- (BOOL) gotLocation
{
	return [self.data objectForKey: @"geo"] || [self.data objectForKey: @"coordinate"];
}

- (NSString*) locationText
{
	NSString* text = [self.user objectForKey: @"location"];
	
	return text;
}

- (NSString*) twitterID
{
	NSString* text = [[self.user objectForKey: @"id"] stringValue];
	
	return text;
}

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
	else
	{
		date = value;
	}

	
	return date;
}

- (NSString*) authorID
{
	return [self.user objectForKey: @"id_str"];
}
@end
