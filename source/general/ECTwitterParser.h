// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 08/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "MGTwitterEngineDelegate.h"

@interface ECTwitterParser : NSObject 
{
	__weak id<MGTwitterEngineDelegate>  mDelegate;
	MGTwitterEngineDeliveryOptions      mOptions;
}

- (id)initWithDelegate:(id<MGTwitterEngineDelegate>)theDelegate options:(MGTwitterEngineDeliveryOptions)options;

- (void)parseData:(NSData*)data identifier:(NSString*)identifier;


@end
