//
//  RZCollectionListTestsBase.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "RZCollectionList.h"
#import "RZCollectionListTestModelObject.h"
#import "TestParentEntity.h"
#import "TestChildEntity.h"

typedef void (^RZCollectionListTestCoreDataBlock)(NSManagedObjectContext *moc);

@interface RZCollectionListTestsBase : XCTestCase

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) NSManagedObjectContext *moc;

- (void)setupTableView;
- (void)setupCoreDataStack;

- (void)insertTestObjectsToMoc;

- (void)performSynchronousCoreDataBlockInChildContext:(RZCollectionListTestCoreDataBlock)block;
- (void)waitFor:(NSUInteger)seconds;

- (void)assertTitlesOfVisibleCells:(NSArray*)titles;

@end
