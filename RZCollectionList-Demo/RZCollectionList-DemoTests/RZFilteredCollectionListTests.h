//
//  RZFilteredCollectionListTests.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class RZArrayCollectionList;
@class RZFilteredCollectionList;

@interface RZFilteredCollectionListTests : SenTestCase

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZFilteredCollectionList *filteredList;

@end
