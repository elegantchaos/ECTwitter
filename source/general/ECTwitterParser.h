// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 08/04/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
// --------------------------------------------------------------------------

#import "MGTwitterEngineDelegate.h"
#import <ECFoundation/ECProperties.h>

@interface ECTwitterParser : NSObject 
{
	__weak id<MGTwitterEngineDelegate>  mDelegate;
	MGTwitterEngineDeliveryOptions      mOptions;

    ECPropertyVariable(identifier, NSString*);
    ECPropertyVariable(stack, NSMutableArray*);
    ECPropertyVariable(currentDictionary, NSMutableDictionary*);
    ECPropertyVariable(currentArray, NSMutableArray*);
    ECPropertyVariable(currentKey, NSString*);
    ECPropertyVariable(parsedObjects, NSMutableArray*);
}

- (id)initWithDelegate:(id<MGTwitterEngineDelegate>)theDelegate options:(MGTwitterEngineDeliveryOptions)options;

- (void)parseData:(NSData*)data identifier:(NSString*)identifier;


@end
