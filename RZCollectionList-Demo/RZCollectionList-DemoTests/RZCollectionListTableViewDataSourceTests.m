//
//  RZCollectionListTableViewDataSourceTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListTableViewDataSourceTests.h"
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"

// Comment this out to not pause as long between tests
#define RZ_TESTS_USER_MODE

#ifdef RZ_TESTS_USER_MODE
#define kWaitTime   3.0
#else
#define kWaitTime   0.125
#endif

@interface RZCollectionListTableViewDataSourceTests () <RZCollectionListTableViewDataSourceDelegate>

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *dataSource;

@property (nonatomic, assign) BOOL shouldContinue;

@end

@implementation RZCollectionListTableViewDataSourceTests

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
    [super tearDown];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWaitTime]];
}

#pragma mark - Tests

- (void)test1ArrayListNonBatch
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];

    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    for (int i=0; i<10; i++){
        STAssertNoThrow([self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], @"Table view exception");
    }
}

- (void)test2ArrayListBatchAddRemove
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];
    
    // remove a few objects at the beginning
    for (int i=0; i<5; i++){
        [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    // insert a few objects at the end
    for (int i=0; i<5; i++){
        NSString *idx = [NSString stringWithFormat:@"%d",i];
        [self.arrayList addObject:idx toSection:0];
    }
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    
}

- (void)test3ArrayListBatchAddRemoveRandomAccess
{
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    self.arrayList.objectUpdateNotifications = @[@"updateMyObject"];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // update title of second cell
    NSMutableString *twoString = [startArray objectAtIndex:2];
    [twoString deleteCharactersInRange:NSMakeRange(0, twoString.length)];
    [twoString appendString:@"third"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:twoString];

    // add object at first index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // move to second index
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add objects at the end
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];
    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    
    // final order should be:
    // first
    // second
    // third
    // 4
    // 5
    // 6
    // 7
    // 8
    // 9
    // penultimate
    // last
    
    UITableViewCell *firstCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    STAssertEqualObjects(firstCell.textLabel.text, @"first", @"Update notification in batch update failed");
    UITableViewCell *secondCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    STAssertEqualObjects(secondCell.textLabel.text, @"second", @"Move notification in batch update failed");
}

- (void)test4ArrayListBatchWithSectionUpdates
{
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.arrayList.objectUpdateNotifications = @[@"updateMyObject"];
    
    // Insert section before and after numbers
    RZArrayCollectionListSectionInfo *newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:0];
    
    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:2];
    
    NSArray *lastSectionStrings = @[@"This",@"is",@"the",@"final",@"section"];
    [lastSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:2]];
    }];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // batch modify sections and objects
        
    [self.arrayList beginUpdates];
    
    [self.arrayList removeSectionAtIndex:0];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // update title of second cell
    NSMutableString *twoString = [startArray objectAtIndex:2];
    [twoString deleteCharactersInRange:NSMakeRange(0, twoString.length)];
    [twoString appendString:@"third"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:twoString];
    
    // add object at first index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // move to second index
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add objects at the end
    NSInteger last = [[self.arrayList.sections objectAtIndex:0] numberOfObjects];
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:last inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:last inSection:0]];
    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];

    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");

}

- (void)test5ModifySectionsAndRows
{
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];

    
    // Insert section before and after numbers
    RZArrayCollectionListSectionInfo *newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:0];
    
    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:2];
    
    NSArray *lastSectionStrings = @[@"This",@"is",@"the",@"last",@"section"];
    [lastSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:2]];
    }];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];
    
    // remove "0"
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    
    // replace with "first"
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    
    // remove section 0
    [self.arrayList removeSectionAtIndex:0];
    
    // remove "1"
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    
    // remove section 2
    [self.arrayList removeSectionAtIndex:1];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");

}

- (void)test6BatchMove
{
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"4"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    // Insert section before and after numbers
    RZArrayCollectionListSectionInfo *newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:0];
    
    NSArray *firstSectionStrings = @[@"A",@"B",@"C"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:0];
    
    firstSectionStrings = @[@"Delete",@"Me"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];
    
    // Delete first section
    [self.arrayList removeSectionAtIndex:0];
    
    // swap 0 and 1
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    
    // swap 0 and 2
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]];
    
    // remove 0
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]];

    // insert after 3
    [self.arrayList insertObject:@"BLAH" atIndexPath:[NSIndexPath indexPathForItem:3 inSection:1]];

    // move 3 to end
    NSInteger last = [[self.arrayList.sections objectAtIndex:1] numberOfObjects] - 1;
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:last inSection:1]];

    // remove first section again
    [self.arrayList removeSectionAtIndex:0];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    STAssertEqualObjects([self.arrayList.listObjects objectAtIndex:2], @"BLAH", @"Something went wrong here");
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWaitTime]];
    
    // start over - test moving row to another section

    self.dataSource = nil;
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    newSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:0];
    [self.arrayList insertSection:newSection atIndex:0];

    firstSectionStrings = @[@"Zero",@"Should",@"Precede",@"Me"];
    [firstSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];
    
    // insert at first row
    [self.arrayList insertObject:@"TEST" atIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    
    // move 1,1 to 0,0
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    STAssertEqualObjects([self.arrayList.listObjects objectAtIndex:0], @"0", @"Zero string was not moved correctly");

}

- (void)test7UpdateAndAddSection
{
    NSArray *startArray = @[[NSMutableString stringWithString:@"0"], [NSMutableString stringWithString:@"1"]];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];    
    self.arrayList.objectUpdateNotifications = @[@"updateMyObject"];

    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [self.arrayList beginUpdates];
    
    NSMutableString *zeroString = [startArray objectAtIndex:0];
    [zeroString deleteCharactersInRange:NSMakeRange(0, zeroString.length)];
    [zeroString appendString:@"zero"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:zeroString];
    
    NSMutableString *oneString = [startArray objectAtIndex:1];
    [oneString deleteCharactersInRange:NSMakeRange(0, oneString.length)];
    [oneString appendString:@"one"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:oneString];
    
    RZArrayCollectionListSectionInfo *sectionZero = [[RZArrayCollectionListSectionInfo alloc] initWithName:@"zero" sectionIndexTitle:@"zero" numberOfObjects:0];
    [self.arrayList insertSection:sectionZero atIndex:0];
    
    [self.arrayList addObject:@"Pre-Numbers" toSection:0];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    STAssertEqualObjects([self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"zero", @"Cell at index 1 should have title \"zero\"");
    STAssertEqualObjects([self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]].textLabel.text, @"one", @"Cell at index 2 should have title \"one\"");
}

- (void)test8SeveralMoves
{
    NSArray *startArray = @[@"1",@"2",@"3",@"4",@"5"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    [self.arrayList beginUpdates];
    
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];

    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    
    // Final order should be 3, 4, 1, 5, 2
    NSArray *finalArray = @[@"3",@"4",@"1",@"5",@"2"];
    STAssertEqualObjects(self.arrayList.listObjects, finalArray, @"Final array order is incorrect");
}

#pragma mark - Table View Data Source

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if ([object isKindOfClass:[NSString class]]){
        cell.textLabel.text = object;
    }
    return cell;
}

@end
