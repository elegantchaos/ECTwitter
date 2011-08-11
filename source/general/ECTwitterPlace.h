// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/10/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <ECFoundation/ECProperties.h>

@interface ECTwitterPlace : NSObject 
{
	ECPropertyVariable(data, NSDictionary*);
	ECPropertyVariable(containers, NSArray*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(data, NSDictionary*);
ECPropertyRetained(containers, NSArray*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithPlaceInfo: (NSDictionary*) dictionary;
- (NSString*) description;
- (NSString*) name;
- (NSString*) type;

@end
