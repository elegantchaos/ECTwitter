// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/08/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>


@interface ECTwitterUser : NSObject 
{
	ECPropertyVariable(data, NSDictionary*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithUserInfo: (NSDictionary*) dictionary;
- (NSString*) description;
- (NSString*) name;
- (NSString*) twitterName;
- (NSString*) twitterID;

@end
