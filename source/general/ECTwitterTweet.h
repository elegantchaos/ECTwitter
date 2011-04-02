// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class CLLocation;
@class ECTwitterID;
@class ECTwitterUser;

@interface ECTwitterTweet : ECTwitterCachedObject 
{
	ECPropertyVariable(twitterID, ECTwitterID*);
	ECPropertyVariable(authorID, ECTwitterID*);
	ECPropertyVariable(cachedAuthor, ECTwitterUser*);
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(text, NSString*);
	ECPropertyVariable(viewed, NSUInteger);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyDefine(text, NSString*, assign, nonatomic, readonly);
ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(authorID, ECTwitterID*);
ECPropertyRetained(cachedAuthor, ECTwitterUser*);

ECPropertyAssigned(viewed, NSUInteger);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (id)				initWithContentsOfURL: (NSURL*) url inCache: (ECTwitterCache*) cache;
- (id)				initWithID: (ECTwitterID*) tweetID inCache: (ECTwitterCache*) cache;

- (BOOL)			gotData;

- (void)			refreshWithInfo: (NSDictionary*) info;

- (NSString*)		description;
- (BOOL)			gotLocation;
//- (NSString*) locationText;
- (CLLocation*)		location;
- (NSDate*)			created;
- (ECTwitterUser*)	author;
- (ECTwitterID*)	authorID;
- (BOOL)			isFavourited;
- (BOOL)			mentionsUser: (ECTwitterUser*) user;

- (NSString*)		inReplyToTwitterName;
- (ECTwitterID*)	inReplyToMessageID;
- (ECTwitterID*)	inReplyToAuthorID;

- (NSString*)		sourceName;
- (NSURL*)			sourceURL;

- (NSComparisonResult) compareByDateAscending: (ECTwitterTweet*) other;
- (NSComparisonResult) compareByDateDescending: (ECTwitterTweet*) other;
- (NSComparisonResult) compareByViewsDateDescending: (ECTwitterTweet*) other;

- (void)			saveTo: (NSURL*) url;

@end


// --------------------------------------------------------------------------
// Public Constants
// --------------------------------------------------------------------------

static const NSInteger kTweetCharacterLimit = 140;
