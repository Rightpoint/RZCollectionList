//
//  RZCollectionListTestModelObject.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListTestModelObject.h"

@implementation RZCollectionListTestModelObject

+ (RZCollectionListTestModelObject*)objectWithName:(NSString *)name number:(NSNumber *)number
{
    RZCollectionListTestModelObject *obj = [RZCollectionListTestModelObject new];
    obj.name = name;
    obj.number = number;
    return obj;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ - %ld", self.name, (long)self.number.integerValue];
}
@end
