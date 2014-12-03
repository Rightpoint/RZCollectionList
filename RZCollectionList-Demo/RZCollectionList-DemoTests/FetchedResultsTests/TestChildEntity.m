//
//  TestChildEntity.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "TestChildEntity.h"


@implementation TestChildEntity

@dynamic name;
@dynamic index;
@dynamic parent;

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ [%ld]", self.name, (long)self.index.integerValue];
}

@end
