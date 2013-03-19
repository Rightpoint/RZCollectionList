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
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    self.arrayList.objectUpdateNotifications = @[@"updateMyObject"];
    
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
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:11 inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:11 inSection:0]];
    
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
    NSArray *startArray = @[@"0",@"1",[NSMutableString stringWithString:@"2"],@"3",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
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
    
    NSArray *lastSectionStrings = @[@"This",@"is",@"the",@"last",@"section"];
    [lastSectionStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.arrayList insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:2]];
    }];
    
    // batch modify sections and objects
        
    [self.arrayList beginUpdates];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    
    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    // update title of second cell
    NSMutableString *twoString = [startArray objectAtIndex:2];
    [twoString deleteCharactersInRange:NSMakeRange(0, twoString.length)];
    [twoString appendString:@"third"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMyObject" object:twoString];
    
    // add object at first index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    // move to second index
//    [self.arrayList moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add objects at the end
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:11 inSection:1]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:11 inSection:1]];
    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:1]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:1]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");

//    UITableViewCell *firstCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
//    STAssertEqualObjects(firstCell.textLabel.text, @"first", @"Update notification in batch update failed");
//    UITableViewCell *secondCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
//    STAssertEqualObjects(secondCell.textLabel.text, @"second", @"Move notification in batch update failed");
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
