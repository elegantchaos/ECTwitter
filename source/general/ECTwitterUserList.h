// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 05/04/2011
//
//  Copyright 2012 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
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
