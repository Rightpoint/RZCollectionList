//
//  RZCollectionListArrayListComboTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListArrayListComboTests.h"
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"

#import "RZCollectionListTestModelObject.h"

#define kRZCollectionListMockObjectUpdated @"MockObjectUpdated"

@interface RZCollectionListArrayListComboTests () <RZCollectionListTableViewDataSourceDelegate>

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZFilteredCollectionList *filteredList;
@property (nonatomic, strong) RZSortedCollectionList *sortedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *dataSource;

@property (nonatomic, assign) BOOL shouldContinue;

- (NSArray*)uniqueStartingObjects;
- (void)waitFor:(NSUInteger)seconds;

@end

@implementation RZCollectionListArrayListComboTests


- (void)setUp{
    [super setUp];
    
    self.viewController = [[UIViewController alloc] init];
    [self.viewController view];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.viewController.view.bounds];
    [self.viewController.view addSubview:self.tableView];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    self.viewController.title = @"Table View Tests";
    self.viewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:nav];

}

- (void)tearDown{
    [self waitFor:1];
    [super tearDown];
}

- (NSArray*)uniqueStartingObjects
{
   return @[ [RZCollectionListTestModelObject objectWithName:@"Albert" number:@3],
             [RZCollectionListTestModelObject objectWithName:@"Bertha" number:@2],
             [RZCollectionListTestModelObject objectWithName:@"Carol" number:@1],
             [RZCollectionListTestModelObject objectWithName:@"Dave" number:@4],
             [RZCollectionListTestModelObject objectWithName:@"Egghead" number:@5] ];
}

- (void)waitFor:(NSUInteger)seconds
{
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

#pragma mark - Data Source

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    if ([object isKindOfClass:[RZCollectionListTestModelObject class]]){
        cell.textLabel.text = [object name];
        cell.detailTextLabel.text = [[object number] stringValue];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView updateCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object isKindOfClass:[RZCollectionListTestModelObject class]])
    {
        cell.textLabel.text = [object name];
        cell.detailTextLabel.text = [[object number] stringValue];
    }
}

#pragma mark - Tests

- (void)test100FilteredArrayBatchUpdate
{
    NSArray *objects = [self uniqueStartingObjects];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:objects sectionNameKeyPath:nil];
    [self.arrayList setObjectUpdateNotifications:@[kRZCollectionListMockObjectUpdated]];
    
    self.filteredList = [[RZFilteredCollectionList alloc] initWithSourceList:self.arrayList predicate:[NSPredicate predicateWithFormat:@"number >= 4"]];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.filteredList
                                                                            delegate:self];
    
    [self waitFor:1.5];

    // Do a batch update and make sure the filtered list gets updated correctly
    [self.arrayList beginUpdates];
    
    [self.arrayList addObject:[RZCollectionListTestModelObject objectWithName:@"Harold" number:@22]
                    toSection:0];
    [self.arrayList addObject:[RZCollectionListTestModelObject objectWithName:@"Jimbo" number:@44]
                    toSection:0];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    
    [objects[0] setNumber:@100];
    [[NSNotificationCenter defaultCenter] postNotificationName:kRZCollectionListMockObjectUpdated object:objects[0]];
    
    [self.arrayList endUpdates];
    
    STAssertEquals(self.filteredList.listObjects.count, (NSUInteger)4, @"Filtered list has wrong number of objects after batch update");
    
    [self waitFor:1.5];
}

- (void)test101SortedArrayBatchUpdate
{
    NSArray *objects = [self uniqueStartingObjects];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:objects sectionNameKeyPath:nil];
    [self.arrayList setObjectUpdateNotifications:@[kRZCollectionListMockObjectUpdated]];
    
    self.sortedList = [[RZSortedCollectionList alloc] initWithSourceList:self.arrayList sortDescriptors:@[]];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.sortedList
                                                                            delegate:self];
    
    [self waitFor:1.5];
    
    self.sortedList.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES],
                                        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    [self waitFor:1.5];

    //!!!: This Fails
    //     The tableview will contain duplicate cells. The index paths coming from the sorted list are not correctly incremented for a sorted insert below a previous insert.
    //     In a more serious case this could cause a tableview animation exception.
    [self.arrayList beginUpdates];
    
    [self.arrayList addObject:[RZCollectionListTestModelObject objectWithName:@"Jimbo" number:@1]
                    toSection:0];
    [self.arrayList addObject:[RZCollectionListTestModelObject objectWithName:@"Harold" number:@2]
                    toSection:0];
    
    [self.arrayList endUpdates];
    
    
    [self waitFor:1.5];
}

@end
