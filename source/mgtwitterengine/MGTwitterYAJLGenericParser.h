//
//  MGTwitterYAJLGenericParser.h
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 18/02/2008.
//  Copyright 2008 Instinctive Code.
//

#include <yajl/yajl_parse.h>
//#import "yajl_parse.h"

#import "MGTwitterEngineDelegate.h"

@interface MGTwitterYAJLGenericParser : NSObject {
	__weak NSObject<MGTwitterEngineDelegate>* delegate; // weak ref
	NSString *identifier;
    NSData* json;
	NSURL *URL;
	NSMutableArray *parsedObjects;
	MGTwitterEngineDeliveryOptions deliveryOptions;
	
	yajl_handle _handle;
}

- (id)initWithData:(NSData*)data
	delegate:(NSObject<MGTwitterEngineDelegate>*)theDelegate 
	connectionIdentifier:(NSString *)identifier
	URL:(NSURL *)URL
	deliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions;


@end
