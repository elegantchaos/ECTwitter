//
//  MGTwitterParserFactoryJSON.m
//
//  Created by Sam Deane on 21/09/2010.
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//

#import "MGTwitterParserFactoryJSON.h"


@implementation MGTwitterParserFactoryJSON

- (id) init
{
	if ((self = [super init]) != nil)
	{
		_deliveryOptions = MGTwitterEngineDeliveryAllResultsOption;
	}
	
	return self;
}

- (MGTwitterEngineDeliveryOptions)deliveryOptions
{
	return _deliveryOptions;
}

- (void)setDeliveryOptions:(MGTwitterEngineDeliveryOptions)deliveryOptions
{
	_deliveryOptions = deliveryOptions;
}

- (NSString*) APIFormat
{
	return @"json";
}

@end
