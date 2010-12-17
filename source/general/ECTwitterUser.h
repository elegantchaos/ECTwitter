// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class ECTwitterID;
@class ECTwitterTweet;

@interface ECTwitterUser : ECTwitterCachedObject  
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(twitterID, ECTwitterID*);
	ECPropertyVariable(tweets, NSMutableArray*);
	ECPropertyVariable(newestTweet, ECTwitterID*);
	ECPropertyVariable(cachedImage, NSImage*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(tweets, NSMutableArray*);
ECPropertyRetained(newestTweet, ECTwitterID*);
ECPropertyRetained(cachedImage, NSImage*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (void)			refreshWithInfo: (NSDictionary*) info;

- (BOOL)			gotData;

- (NSString*)		description;
- (NSString*)		name;
- (NSString*)		twitterName;
- (NSString*)		longDisplayName;

- (NSString*)		bio;

- (NSImage*)		image;

- (void)			addTweet: (ECTwitterTweet*) tweet;

- (void)			requestTimeline;
- (void)			refreshTimeline;

@end
