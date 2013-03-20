//
//  RZCollectionListCollectionViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListCollectionViewDataSource.h"
#import "RZCollectionListUIKitDataSourceAdapter.h"

typedef void(^RZCollectionListCollectionViewBatchUpdateBlock)(void);

@interface RZCollectionListCollectionViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, strong, readwrite) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *batchUpdates;

@property (nonatomic, strong) RZCollectionListUIKitDataSourceAdapter *observerAdapter;

@end

@implementation RZCollectionListCollectionViewDataSource

- (id)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate
{
    if ((self = [super init]))
    {
        self.collectionList = collectionList;
        self.delegate = delegate;
        self.collectionView = collectionView;
        
        [self.collectionList addCollectionListObserver:self];
        
        self.animateCollectionChanges = YES;
        self.useBatchUpdating = YES;
        collectionList.delegate = self;
        
        collectionView.dataSource = self;
        [collectionView reloadData];
    }
    
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self.observerAdapter];
}

#pragma mark - Properties

- (void)setUseBatchUpdating:(BOOL)useBatchUpdating
{
    if (_useBatchUpdating != useBatchUpdating){
        
        // Can't use adapter for non-batch updates
        if (!useBatchUpdating){
            if (self.observerAdapter != nil){
                [self.collectionList removeCollectionListObserver:self.observerAdapter];
                self.observerAdapter = nil;
            }
            [self.collectionList addCollectionListObserver:self];
        }
        else{
            self.observerAdapter = [[RZCollectionListUIKitDataSourceAdapter alloc] initWithObserver:self];
            [self.collectionList removeCollectionListObserver:self];
            [self.collectionList addCollectionListObserver:self.observerAdapter];
        }
    }
    _useBatchUpdating = useBatchUpdating;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id<RZCollectionListSectionInfo> sectionInfo = [self.collectionList.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.collectionList objectAtIndexPath:indexPath];
    return [self.delegate collectionView:collectionView cellForObject:object atIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.collectionList.sections count];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *view = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)])
    {
        view = [self.delegate collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    }
    
    return view;
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    if (self.animateCollectionChanges)
    {
        RZCollectionListCollectionViewBatchUpdateBlock objectChangeBlock = ^{
            switch(type) {
                case RZCollectionListChangeInsert:
                    [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]];
                    break;
                case RZCollectionListChangeDelete:
                    [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                    break;
                case RZCollectionListChangeMove:
                    [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
                    break;
                case RZCollectionListChangeUpdate:
                {
                    [self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                }
                    break;
                default:
                    //uncaught type
                    NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
                    break;
            }
        };
        
        if (self.useBatchUpdating && nil != self.batchUpdates)
        {
            [self.batchUpdates addObject:[objectChangeBlock copy]];
        }
        else
        {
            objectChangeBlock();
        }
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    if (self.animateCollectionChanges)
    {
        RZCollectionListCollectionViewBatchUpdateBlock sectionChangeBlock = ^{
            switch(type) {
                case RZCollectionListChangeInsert:
                    [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                    break;
                    
                case RZCollectionListChangeDelete:
                    [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                    break;
                    
                default:
                    //uncaught type
                    NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
                    break;
            }
        };
        
        if (self.useBatchUpdating && nil != self.batchUpdates)
        {
            [self.batchUpdates addObject:[sectionChangeBlock copy]];
        }
        else
        {
            sectionChangeBlock();
        }
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.animateCollectionChanges)
    {
        if (self.useBatchUpdating)
        {
            self.batchUpdates = [NSMutableArray array];
        }
    }
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.animateCollectionChanges)
    {
        if (self.useBatchUpdating)
        {
            if (nil != self.batchUpdates)
            {
                [self.collectionView performBatchUpdates:^{
                    [self.batchUpdates enumerateObjectsUsingBlock:^(RZCollectionListCollectionViewBatchUpdateBlock changeBlock, NSUInteger idx, BOOL *stop) {
                        changeBlock();
                    }];
                } completion:^(BOOL finished) {
                    [self.batchUpdates removeAllObjects];
                    self.batchUpdates = nil;
                }];
            }
        }
    }
    else
    {
        [self.collectionView reloadData];
    }
}

#pragma mark - RZCollectionListDelegate

- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName
{
    return nil;
}


@end
