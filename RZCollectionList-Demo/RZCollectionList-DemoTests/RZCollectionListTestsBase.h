//
//  RZCollectionListTestsBase.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <CoreData/CoreData.h>
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"


@interface RZCollectionListTestsBase : SenTestCase

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) NSManagedObjectContext *moc;

- (void)setupTableView;
- (void)setupCoreDataStack;

- (void)waitFor:(NSUInteger)seconds;

@end
