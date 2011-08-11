// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import <ECFoundation/ECProperties.h>

@class ECTwitterUser;

@interface ECTwitterUserList : NSObject 
{
	ECPropertyVariable(users, NSMutableArray*);
}

// --------------------------------------------------------------------------
// Public Properties
// --------------------------------------------------------------------------

ECPropertyRetained(users, NSMutableArray*);

// --------------------------------------------------------------------------
// Public Methods
// --------------------------------------------------------------------------

- (void)				addUser: (ECTwitterUser*) user;
- (ECTwitterUserList*)	sortedWithSelector: (SEL) selector;

@end
