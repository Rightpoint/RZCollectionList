//
//  RZCompositeCollectionListTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/24/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCompositeCollectionListTests.h"

@interface RZCompositeCollectionListTests () <RZCollectionListTableViewDataSourceDelegate>

@end

@implementation RZCompositeCollectionListTests

- (void)setUp
{
    [super setUp];
    [self setupTableView];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - Tests

- (void)test100MultipleArrayLists
{
    RZArrayCollectionListSectionInfo *section0 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"0" sectionIndexTitle:nil numberOfObjects:3];
    RZArrayCollectionListSectionInfo *section1 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"1" sectionIndexTitle:nil numberOfObjects:3];
    section1.indexOffset = 3;
    
    RZArrayCollectionList * array1 = [[RZArrayCollectionList alloc] initWithArray:@[@"1", @"2", @"3", @"4", @"5", @"6"] sections:@[section0, section1]];
    RZArrayCollectionList * array2 = [[RZArrayCollectionList alloc] initWithArray:@[@"A", @"B", @"C", @"D", @"E"] sectionNameKeyPath:nil];
    RZCompositeCollectionList *composite = [[RZCompositeCollectionList alloc] initWithSourceLists:@[array1, array2]];
        
    __attribute__((unused))
    RZCollectionListTableViewDataSource *dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                                                      collectionList:composite
                                                                                                            delegate:self];
    [self waitFor:1];
    
    [array1 beginUpdates];
    
    [array1 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [array1 moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    
    STAssertNoThrow([array1 endUpdates], @"Something went wrong");
    
    [self waitFor:1];

    [array1 beginUpdates];
    
    [array1 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    [array1 removeSectionAtIndex:1];
    
    STAssertNoThrow([array1 endUpdates], @"Something went wrong");
    
    [self waitFor:1];
    
}

#pragma mark - Table Data Source

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if ([object isKindOfClass:[NSString class]])
    {
        cell.textLabel.text = object;
    }
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Section %d", section];
}

@end
