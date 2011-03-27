// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "ECTwitterCachedObject.h"

@class ECTwitterID;
@class ECTwitterTimeline;
@class ECTwitterTweet;

@interface ECTwitterUser : ECTwitterCachedObject  
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(twitterID, ECTwitterID*);
	ECPropertyVariable(timeline, ECTwitterTimeline*);
	ECPropertyVariable(mentions, ECTwitterTimeline*);
	ECPropertyVariable(cachedImage, NSImage*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(timeline, ECTwitterTimeline*);
ECPropertyRetained(mentions, ECTwitterTimeline*);
ECPropertyRetained(posts, ECTwitterTimeline*);
ECPropertyRetained(cachedImage, NSImage*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id)				initWithInfo: (NSDictionary*) info inCache: (ECTwitterCache*) cache;
- (id)				initWithContentsOfURL: (NSURL*) url inCache: (ECTwitterCache*) cache;
- (void)			refreshWithInfo: (NSDictionary*) info;

- (BOOL)			gotData;

- (NSString*)		description;
- (NSString*)		name;
- (NSString*)		twitterName;
- (NSString*)		longDisplayName;

- (NSString*)		bio;

- (NSImage*)		image;

- (void)			addTweet: (ECTwitterTweet*) tweet;
- (void)			addPost: (ECTwitterTweet*) tweet;

- (void)			requestTimeline;
- (void)			refreshTimeline;

- (void)			requestPosts;
- (void)			refreshPosts;

- (void)			saveTo: (NSURL*) url;

@end
