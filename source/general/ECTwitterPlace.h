// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/10/2010
//
//  Copyright 2010 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@interface ECTwitterPlace : NSObject 
{

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
