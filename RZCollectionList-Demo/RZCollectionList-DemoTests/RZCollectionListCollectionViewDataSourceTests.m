//
//  RZCollectionListCollectionViewDataSourceTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 4/3/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListCollectionViewDataSourceTests.h"
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCollectionListCollectionViewDataSource.h"

// Comment this out to not pause as long between tests
#define RZ_TESTS_USER_MODE

#ifdef RZ_TESTS_USER_MODE
#define kWaitTime   3.0
#else
#define kWaitTime   0.125
#endif

@interface RZCollectionListCollectionViewDataSourceTests () <RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *dataSource;

@property (nonatomic, assign) BOOL shouldContinue;

@end

@implementation RZCollectionListCollectionViewDataSourceTests

- (void)setUp{
    
    [super setUp];
    
    self.viewController = [[UIViewController alloc] init];
    [self.viewController view];
    
    UICollectionViewFlowLayout *aFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [aFlowLayout setMinimumInteritemSpacing:4];
    [aFlowLayout setMinimumLineSpacing:4];
    [aFlowLayout setItemSize:CGSizeMake(80, 100)];
    [aFlowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.viewController.view.bounds collectionViewLayout:aFlowLayout];
    [self.viewController.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"testCell"];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    self.viewController.title = @"Collection View Tests";
    self.viewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:nav];
}

- (void)tearDown{
    [super tearDown];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kWaitTime]];
}

#pragma mark -tests

- (void)test1ArrayListNonBatch
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                                                collectionList:self.arrayList
                                                                                      delegate:self];
    
    // For some reason collection view needs some time
    // in the run loop before it's ready to be changed
    [self waitFor:1];

    XCTAssertNoThrow([self.arrayList addObject:@"End" toSection:0], @"Collection View Exception");
}

- (void)test2ArrayListBatchAddRemove
{
    NSArray *startArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                                                collectionList:self.arrayList
                                                                                      delegate:self];
    
    [self waitFor:1];
    
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
    
    XCTAssertNoThrow([self.arrayList endUpdates], @"Collection View exception");
    
}

- (void)test3DeleteInsertAndMove
{
    NSArray *startArray = @[@"a",@"b",@"c",@"6",@"d",@"e",@"f",@"g",@"h",@"1"];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:startArray sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                                                collectionList:self.arrayList
                                                                                      delegate:self];
    
    [self waitFor:1];
    
    [self.arrayList beginUpdates];
    
    // delete letters
    for (int i=0; i<3; i++){
        [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    for (int i=0; i<5; i++){
        [self.arrayList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    }

    // Insert missing numbers back in
    for (int i=0; i<10; i++){
        if (i == 1 || i == 6) continue;
        [self.arrayList insertObject:[NSString stringWithFormat:@"%d",i] atIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    // Move numbers to their proper place
    NSIndexPath * oneIndexPath = [self.arrayList indexPathForObject:@"1"];
    [self.arrayList moveObjectAtIndexPath:oneIndexPath toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    NSIndexPath * sixIndexPath = [self.arrayList indexPathForObject:@"6"];
    [self.arrayList moveObjectAtIndexPath:sixIndexPath toIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    
    XCTAssertNoThrow([self.arrayList endUpdates], @"Collection View exception");
}

#pragma mark - RZCollectionListCollectionViewDataSource

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"testCell" forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *string = (NSString*)object;

    CGSize itemSize = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, itemSize.width, itemSize.height/2)];
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    titleLabel.text = string;

    [cell.contentView addSubview:titleLabel];
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];
    
    return cell;
}

@end
