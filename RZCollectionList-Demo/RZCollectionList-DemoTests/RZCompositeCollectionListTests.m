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
    
    NSArray *sect2Objs = @[@"A", @"B", @"C", @"D", @"E"];
    
    RZArrayCollectionList * array1 = [[RZArrayCollectionList alloc] initWithArray:@[@"1", @"2", @"3", @"4", @"5", @"6"] sections:@[section0, section1]];
    RZArrayCollectionList * array2 = [[RZArrayCollectionList alloc] initWithArray:sect2Objs sectionNameKeyPath:nil];
    RZCompositeCollectionList *composite = [[RZCompositeCollectionList alloc] initWithSourceLists:@[array1, array2]];
        
    __attribute__((unused))
    RZCollectionListTableViewDataSource *dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                                                      collectionList:composite
                                                                                                            delegate:self];
    
    NSArray *startObjs0 = @[@"1",@"2",@"3"];
    NSArray *startObjs1 = @[@"4",@"5",@"6"];
    
    STAssertEqualObjects(startObjs0, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    STAssertEqualObjects(startObjs1, [[[composite sections] objectAtIndex:1] objects], @"Incorrect starting objects in section 1");
    STAssertEqualObjects(sect2Objs, [[[composite sections] objectAtIndex:2] objects], @"Incorrect starting objects in section 2");
    
    [self waitFor:1];
    
    [array1 beginUpdates];
    
    [array1 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [array1 moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    
    STAssertNoThrow([array1 endUpdates], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[@"2",@"3",@"4",@"5",@"6",@"A",@"B",@"C",@"D",@"E"]];
    
    NSArray *finalObjs0 = @[@"2",@"3",@"4"];
    NSArray *finalObjs1 = @[@"5",@"6"];
    
    STAssertEqualObjects(finalObjs0, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    STAssertEqualObjects(finalObjs1, [[[composite sections] objectAtIndex:1] objects], @"Incorrect starting objects in section 1");
    STAssertEqualObjects(sect2Objs, [[[composite sections] objectAtIndex:2] objects], @"Incorrect starting objects in section 2");
    
    [self waitFor:1];

    [array1 beginUpdates];
    
    [array1 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    [array1 removeSectionAtIndex:1];
    
    STAssertNoThrow([array1 endUpdates], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[@"2",@"3",@"4",@"A",@"B",@"C",@"D",@"E"]];
    
    finalObjs0 = @[@"2",@"3",@"4"];
    
    STAssertEqualObjects(finalObjs0, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    STAssertEqualObjects(sect2Objs, [[[composite sections] objectAtIndex:1] objects], @"Incorrect starting objects in section 2");
    
    [self waitFor:1];
    
}

- (void)test101FilterAndArraySections
{

    NSArray *section0Objs = @[@"A", @"B", @"C"];
    NSArray *section1Objs = @[@"1", @"2", @"3", @"4", @"5"];

    
    RZArrayCollectionList * array1 = [[RZArrayCollectionList alloc] initWithArray:section0Objs sectionNameKeyPath:nil];
    RZArrayCollectionList * array2 = [[RZArrayCollectionList alloc] initWithArray:section1Objs sectionNameKeyPath:nil];
    RZFilteredCollectionList * filter = [[RZFilteredCollectionList alloc] initWithSourceList:array2 predicate:nil];
    
    RZCompositeCollectionList *composite = [[RZCompositeCollectionList alloc] initWithSourceLists:@[array1, filter]];
    
    __attribute__((unused))
    RZCollectionListTableViewDataSource *dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                                                      collectionList:composite
                                                                                                            delegate:self];
    
    STAssertEqualObjects(section0Objs, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    STAssertEqualObjects(section1Objs, [[[composite sections] objectAtIndex:1] objects], @"Incorrect starting objects in section 1");

    [self waitFor:1];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) { return ([evaluatedObject integerValue] > 3); }];
    
    STAssertNoThrow([filter setPredicate:predicate], @"Exception on setting predicate");
    
    NSArray *filtObjs = @[@"4",@"5"];
    STAssertEqualObjects(filtObjs, [[[composite sections] objectAtIndex:1] objects], @"Incorrect objects in section 1 after filter");
    
    [self waitFor:1];
    
    [array2 beginUpdates];
    
    [array2 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [array2 addObject:@"22" toSection:0];
    
    STAssertNoThrow([array2 endUpdates], @"Something went wrong");
    
    filtObjs = @[@"4",@"5",@"22"];
    
    STAssertEqualObjects(filtObjs, [[[composite sections] objectAtIndex:1] objects], @"Incorrect objects in section 1 after update");
    
    [self waitFor:1];
}

- (void)test101MultipleArrayListsWithFlattenedSections
{
    RZArrayCollectionListSectionInfo *section0 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"0" sectionIndexTitle:nil numberOfObjects:3];
    RZArrayCollectionListSectionInfo *section1 = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"1" sectionIndexTitle:nil numberOfObjects:3];
    section1.indexOffset = 3;
    
    NSArray *sect2Objs = @[@"A", @"B", @"C", @"D", @"E"];
    
    RZArrayCollectionList * array1 = [[RZArrayCollectionList alloc] initWithArray:@[@"1", @"2", @"3", @"4", @"5", @"6"] sections:@[section0, section1]];
    RZArrayCollectionList * array2 = [[RZArrayCollectionList alloc] initWithArray:sect2Objs sectionNameKeyPath:nil];
    RZCompositeCollectionList *composite = [[RZCompositeCollectionList alloc] initWithSourceLists:@[array1, array2] ignoreSections:YES];
    
    __attribute__((unused))
    RZCollectionListTableViewDataSource *dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                                                      collectionList:composite
                                                                                                            delegate:self];
    
    NSArray *startObjs = @[@"1",@"2",@"3",@"4",@"5",@"6",@"A", @"B", @"C", @"D", @"E"];
    
    STAssertEquals([composite sections].count, (NSUInteger)1, @"Composite list should have only one section");
    STAssertEqualObjects(startObjs, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    
    [self waitFor:1];
    
    [array1 beginUpdates];
    
    [array1 removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [array1 moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]]; // should cause no change, actually
    [array1 insertObject:@"Uno" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    STAssertNoThrow([array1 endUpdates], @"Something went wrong");
    
    [array2 beginUpdates];
    
    [array2 removeObject:@"A"];
    [array2 insertObject:@"A point 5" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    STAssertNoThrow([array2 endUpdates], @"Something went wrong");
    
    NSArray *finalObjs = @[@"Uno",@"2",@"3",@"4",@"5",@"6",@"A point 5",@"B",@"C",@"D",@"E"];
    
    [self assertTitlesOfVisibleCells:finalObjs];
    
    STAssertEquals([composite sections].count, (NSUInteger)1, @"Composite list should have only one section");
    STAssertEqualObjects(finalObjs, [[[composite sections] objectAtIndex:0] objects], @"Incorrect starting objects in section 0");
    
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
