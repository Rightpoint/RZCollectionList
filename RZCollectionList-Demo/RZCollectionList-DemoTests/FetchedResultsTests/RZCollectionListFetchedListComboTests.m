//
//  RZCollectionListFetchedListComboTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListFetchedListComboTests.h"
#import "TestChildEntity.h"

@interface RZCollectionListFetchedListComboTests ()

@end

@implementation RZCollectionListFetchedListComboTests

- (void)setUp
{
    [super setUp];
    [self setupTableView];
    [self setupCoreDataStack];
}

- (void)tearDown
{
    [self waitFor:1];
    [super tearDown];
}

#pragma mark - Tests

- (void)test100
{
    
}

@end
