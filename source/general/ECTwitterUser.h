// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class ECTwitterID;
@class ECTwitterTweet;

@interface ECTwitterUser : NSObject 
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(twitterID, ECTwitterID*);
	ECPropertyVariable(tweets, NSMutableArray*);
	ECPropertyVariable(newestTweet, ECTwitterID*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(twitterID, ECTwitterID*);
ECPropertyRetained(tweets, NSMutableArray*);
ECPropertyRetained(newestTweet, ECTwitterID*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithInfo: (NSDictionary*) info;
- (void) refreshWithInfo: (NSDictionary*) info;

- (BOOL) gotData;

- (NSString*) description;
- (NSString*) name;
- (NSString*) twitterName;

- (void) addTweet: (ECTwitterTweet*) tweet;

@end
