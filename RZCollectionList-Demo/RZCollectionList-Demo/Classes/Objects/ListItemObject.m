//
//  ListItemObject.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "ListItemObject.h"

@implementation ListItemObject

+ (id)listItemObjectWithName:(NSString*)itemName subtitle:(NSString*)subtitle
{
    return [[ListItemObject alloc] initWithItemName:itemName subtitle:subtitle];
}

- (id)initWithItemName:(NSString*)itemName subtitle:(NSString*)subtitle
{
    if ((self = [super init]))
    {
        self.itemName = itemName;
        self.subtitle = subtitle;
    }
    
    return self;
}

- (void)commitChanges
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kRZCollectionListItemUpdateNotificationName object:self];
}

@end
