// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/10/2010
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@interface ECTwitterPlace : NSObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSDictionary* data;
@property (nonatomic, retain) NSArray* containers;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (id) initWithPlaceInfo: (NSDictionary*) dictionary;
- (NSString*) description;
- (NSString*) name;
- (NSString*) type;

@end
