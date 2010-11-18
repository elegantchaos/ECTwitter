// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface ECTwitterUser : NSObject 
{
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSMutableDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithUserInfo: (NSMutableDictionary*) dictionary;
- (NSString*) description;
- (NSString*) name;
- (NSString*) twitterName;
- (NSString*) twitterID;

@end
