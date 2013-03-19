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
#import "RZFetchedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"

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
    
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    self.viewController.title = @"Table View Tests";
    self.viewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:nav];
}

- (void)tearDown{
    [super tearDown];
}


#pragma mark - Tests

- (void)test1ArrayListNonBatch
{
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
    for (int i=0; i<10; i++){
        STAssertNoThrow([self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], @"Table view exception");
    }
}

- (void)test2ArrayListBatchAddRemove
{
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
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];

    [self.arrayList beginUpdates];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // insert object at second index
    [self.arrayList insertObject:@"first" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add object at second index
    [self.arrayList insertObject:@"second" atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    
    // add objects at the end
    [self.arrayList insertObject:@"last" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];
    [self.arrayList insertObject:@"penultimate" atIndexPath:[NSIndexPath indexPathForRow:10 inSection:0]];

    
    // delete a few interediate objects
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
    
    // so we can see the result
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
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
