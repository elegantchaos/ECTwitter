// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

@class ECTwitterUser;

@interface ECTwitterUserList : NSObject 

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

@property (nonatomic, retain) NSMutableArray* users;

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (void)				addUser: (ECTwitterUser*) user;
- (ECTwitterUserList*)	sortedWithSelector: (SEL) selector;

@end
