// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface ECTwitterTweet : NSObject 
{
	ECPropertyVariable(data, NSMutableDictionary*);
	ECPropertyVariable(user, NSMutableDictionary*);
	ECPropertyVariable(text, NSString*);
	ECPropertyVariable(source, NSString*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSMutableDictionary*);
ECPropertyRetained(user, NSMutableDictionary*);
ECPropertyDefine(text, NSString*, assign, nonatomic, readonly);
ECPropertyDefine(source, NSString*, assign, nonatomic, readonly);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithDictionary: (NSMutableDictionary*) dictionary;
- (NSString*) description;
- (BOOL) gotLocation;
- (NSString*) locationText;
- (CLLocation*) location;
- (NSDate*) created;
- (NSString*) twitterID;

@end
