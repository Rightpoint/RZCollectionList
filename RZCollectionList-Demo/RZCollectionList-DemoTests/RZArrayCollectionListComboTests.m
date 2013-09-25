//
//  RZCollectionListArrayListComboTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZArrayCollectionListComboTests.h"

#define kRZCollectionListMockObjectUpdated @"MockObjectUpdated"

@interface RZArrayCollectionListComboTests () <RZCollectionListTableViewDataSourceDelegate>

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZFilteredCollectionList *filteredList;
@property (nonatomic, strong) RZSortedCollectionList *sortedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *dataSource;

- (NSArray*)uniqueStartingObjects;

@end

@implementation RZArrayCollectionListComboTests


- (void)setUp{
    [super setUp];
    [self setupTableView];
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
             [RZCollectionListTestModelObject objectWithName:@"Eugene" number:@5] ];
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

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Section %d", section];
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
    
    STAssertNoThrow([self.arrayList endUpdates], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[ @"Albert", @"Eugene", @"Harold", @"Jimbo" ]];
    
    [self waitFor:1.5];
}

- (void)test101FilteredArrayBatchUpdateWithMoves
{
    NSArray *objects0 = [self uniqueStartingObjects];
    NSArray *objects1 = @[ [RZCollectionListTestModelObject objectWithName:@"Jim" number:@10],
                           [RZCollectionListTestModelObject objectWithName:@"Joe" number:@10],
                           [RZCollectionListTestModelObject objectWithName:@"Bob" number:@10] ];
    
    RZArrayCollectionListSectionInfo *section0 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"one" sectionIndexTitle:nil numberOfObjects:objects0.count];
    RZArrayCollectionListSectionInfo *section1 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"two" sectionIndexTitle:nil numberOfObjects:objects1.count];
    section1.indexOffset = objects0.count;
    
    NSMutableArray *allobjects = [objects0 mutableCopy];
    [allobjects addObjectsFromArray:objects1];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:allobjects sections:@[section0, section1]];
    
    [self.arrayList setObjectUpdateNotifications:@[kRZCollectionListMockObjectUpdated]];
    
    self.filteredList = [[RZFilteredCollectionList alloc] initWithSourceList:self.arrayList predicate:[NSPredicate predicateWithFormat:@"number >= 4"]];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.filteredList
                                                                            delegate:self];
    
    [self waitFor:1.5];
    
    [self.arrayList beginUpdates];
    
    // insert new filtered object in section 0
    [self.arrayList insertObject:[RZCollectionListTestModelObject objectWithName:@"Maurice" number:@7] atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // move object to section 1
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[ @"Maurice", @"Eugene", @"Dave", @"Jim", @"Joe", @"Bob" ]];
    
    [self waitFor:1.5];
}

- (void)test102FilteredArrayBatchUpdateWithInsertAndMove


- (void)test200SortedArrayBatchUpdate
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
    
    STAssertNoThrow([self.arrayList endUpdates], @"Something went wrong");

    [self waitFor:1.5];
}

@end
