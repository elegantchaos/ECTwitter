// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
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
	ECPropertyVariable(viewed, BOOL);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyDefine(text, NSString*, assign, nonatomic, readonly);
ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(authorID, ECTwitterID*);
ECPropertyRetained(cachedAuthor, ECTwitterUser*);

ECPropertyAssigned(viewed, BOOL);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (id) initWithID: (ECTwitterID*) tweetID inCache: (ECTwitterCache*) cache;

- (BOOL) gotData;

- (void) refreshWithInfo: (NSDictionary*) info;

- (NSString*) description;
- (BOOL) gotLocation;
//- (NSString*) locationText;
- (CLLocation*) location;
- (NSDate*) created;
- (ECTwitterUser*) author;
- (ECTwitterID*) authorID;
- (BOOL) isFavourited;

- (NSString*)		inReplyToTwitterName;
- (ECTwitterID*)	inReplyToMessageID;
- (ECTwitterID*)	inReplyToAuthorID;

- (NSString*) sourceName;
- (NSURL*) sourceURL;

- (NSComparisonResult) compareByDateAscending: (ECTwitterTweet*) other;
- (NSComparisonResult) compareByDateDescending: (ECTwitterTweet*) other;

@end
