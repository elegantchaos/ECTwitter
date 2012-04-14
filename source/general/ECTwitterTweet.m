// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "ECTwitterTweet.h"
#import "ECTwitterID.h"
#import "ECTwitterCache.h"
#import "ECTwitterUser.h"
#import "ECTwitterTimeline.h"

#import <ECFoundation/NSString+ECCore.h>

#import "RegexKitLite.h"

@implementation ECTwitterTweet

ECDefineDebugChannel(TweetChannel);

// --------------------------------------------------------------------------
// Properties
// --------------------------------------------------------------------------

@synthesize data;
@synthesize cachedAuthor;
@synthesize twitterID;
@synthesize authorID;
@synthesize viewed;

// --------------------------------------------------------------------------
//! Set up with data properties.
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache
{
	if ((self = [super initWithCache: cache]) != nil)
	{
        [self refreshWithInfo:info];
		self.twitterID = [ECTwitterID idFromDictionary: info];
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up with just an ID
// --------------------------------------------------------------------------

- (id) initWithID:(ECTwitterID*)idIn inCache:(ECTwitterCache*)cache
{
	if ((self = [super initWithCache:cache]) != nil)
	{
		self.twitterID = idIn;
	}
	
	return self;
}

// --------------------------------------------------------------------------
//! Set up from a coder.
// --------------------------------------------------------------------------

- (id)initWithCoder:(NSCoder*)coder
{
    // get the tweet id
    ECTwitterID* tweetID = [coder decodeObjectForKey:@"id"];
    
    // is there already an instance with this id in the cache?
    ECTwitterCache* cache = [ECTwitterCache decodingCache];
    ECTwitterTweet* existing = [cache.tweets objectForKey:tweetID.string];
    if (existing)
    {
        // use the cached instance instead of this one
        [self release];
        self = [existing retain];
    }
    else
    {
        // put this object into the cache now so that restoring other objects below will pick it up
        self = [super initWithCache:cache];
        [cache.tweets setObject:self forKey:tweetID.string];
    }
            
    ECAssertNonNil(self);
    if (self)
    {
        self.twitterID = tweetID;
        self.viewed = [coder decodeIntegerForKey:@"viewed"];
        NSDictionary* info = [coder decodeObjectForKey:@"info"];
        [self refreshWithInfo:info];
        NSLog(@"restored tweet %@ with view count %ld", self.twitterID, self.viewed);
    }
    
    return self;
}

// --------------------------------------------------------------------------
//! Update the tweet data.
// --------------------------------------------------------------------------

- (void) refreshWithInfo:(NSDictionary *)info
{
	self.data = info;
    NSDictionary* authorInfo = [info objectForKey: @"user"];
    if (authorInfo)
    {
        // this is a normal tweet
        self.authorID = [ECTwitterID idFromDictionary: authorInfo];
    }
    else
    {
        NSString* searchAuthor = [info objectForKey:@"from_user_id_str"];
        if (searchAuthor)
        {
            // this is a search result - the author is given in a different format
            self.authorID = [ECTwitterID idFromString:searchAuthor];
        }
    }
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
	[data release];
	[authorID release];
	[twitterID release];
	[cachedAuthor release];
	
	[super dealloc];
}

- (NSString*) description
{
    NSString* truncated = [self.text truncateToLength:20];
    NSString* date = [NSDateFormatter localizedStringFromDate:self.created dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
	return [NSString stringWithFormat: @"%@: '%@' %@ views:%d #%@", self.author.twitterName, truncated, date, self.viewed, self.twitterID];
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

- (NSComparisonResult) compareByDateAscending: (ECTwitterTweet*) other
{
	return [self.created compare: other.created];
}

- (NSComparisonResult) compareByDateDescending: (ECTwitterTweet*) other
{
	return [other.created compare: self.created];
}

- (NSComparisonResult) compareByViewsDateDescending: (ECTwitterTweet*) other;
{
	if (self.viewed < other.viewed)
	{
		return NSOrderedAscending;
	}
	else if (self.viewed > other.viewed)
	{
		return NSOrderedDescending;
	}
	else
	{
		// compare by date
		return [other.created compare: self.created];
	}

}

- (NSString*) inReplyToTwitterName
{
	return [self.data objectForKey: @"in_reply_to_screen_name"];
}

- (ECTwitterID*) inReplyToMessageID
{
	ECTwitterID* result = nil;
	NSString* string = [self.data objectForKey: @"in_reply_to_status_id_str"];
	if (string)
	{
		result = [ECTwitterID idFromString:string];
	}
	
	return result;
}

- (ECTwitterID*) inReplyToAuthorID
{
	ECTwitterID* result = nil;
	NSString* string = [self.data objectForKey: @"in_reply_to_user_id_str"];
	if (string)
	{
		result = [ECTwitterID idFromString:string];
	}
	
	return result;
}

static NSString *const kSourceExpression = @"<a.+href=\"(.*)\".*>(.*)</a>";

- (NSString*) sourceName
{
	NSString* source = [self.data objectForKey: @"source"];
	NSArray* captures = [source captureComponentsMatchedByRegex: kSourceExpression];
	NSString* result = nil;
	if ([captures count] == 3)
	{
		result = [captures objectAtIndex: 2];
	}

	return result;
}

// --------------------------------------------------------------------------

- (NSURL*) sourceURL
{
	NSString* source = [self.data objectForKey: @"source"];
	NSArray* captures = [source captureComponentsMatchedByRegex: kSourceExpression];
	NSURL* result = nil;
	if ([captures count] == 3)
	{
		result = [NSURL URLWithString: [captures objectAtIndex: 1]];
	}
	
	return result;
}

// --------------------------------------------------------------------------

- (BOOL) mentionsUser:(ECTwitterUser *)user
{
	NSString* text = [self text];
	NSString* name = [NSString stringWithFormat:@"@%@", user.twitterName];
	return [text rangeOfString: name].length > 0;
}

// --------------------------------------------------------------------------
//! Save the tweet to a file.
// --------------------------------------------------------------------------

- (void)encodeWithCoder:(NSCoder*)coder
{
	NSDictionary* info = self.data;
	if (!info)
	{
		info = [NSDictionary dictionaryWithObject: self.twitterID.string forKey: @"id_str"];
	}
    
    [coder encodeObject:self.twitterID forKey:@"id"];
    [coder encodeObject:info forKey:@"info"];
    [coder encodeInteger:self.viewed forKey:@"viewed"];
    NSLog(@"saved tweet %@ with view count %ld", self.twitterID, self.viewed);
}

@end
