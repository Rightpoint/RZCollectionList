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
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.arrayList
                                                                            delegate:self];
    
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
    for (int i=0; i<10; i++){
        STAssertNoThrow([self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], @"Table view exception");
    }
}

- (void)test2ArrayListBatchAddRemove
{    
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

    [self.arrayList beginUpdates];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add object
    [self.arrayList addObject:@"10" toSection:0];

    // remove first object
    [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    // add object at index 3
    [self.arrayList insertObject:@"3" atIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    
    STAssertNoThrow([self.arrayList endUpdates], @"Table View exception");
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
