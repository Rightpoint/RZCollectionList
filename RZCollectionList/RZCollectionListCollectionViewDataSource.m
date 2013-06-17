//
//  RZCollectionListCollectionViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListCollectionViewDataSource.h"

typedef void(^RZCollectionListCollectionViewBatchUpdateBlock)(void);

@interface RZCollectionListCollectionViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, strong, readwrite) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *batchUpdates;
@property (nonatomic, strong) NSMutableSet *updatedObjects;

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
        
        self.updatedObjects = [NSMutableSet setWithCapacity:16];
    }
    
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self];
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
        if (type == RZCollectionListChangeUpdate){

            if (self.useBatchUpdating){
                [self.updatedObjects addObject:object];
            }
            else{
                [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }
        }
        else{
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
            
                // delayed item updates
                if (self.updatedObjects.count > 0){
                    
                    NSMutableArray *updateIndexPaths = [NSMutableArray arrayWithCapacity:self.updatedObjects.count];
                    [self.updatedObjects enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        NSIndexPath *ip = [self.collectionList indexPathForObject:obj];
                        if (ip != nil){
                            [updateIndexPaths addObject:ip];
                        }
                    }];
                    
                    [self.collectionView performBatchUpdates:^{
                        [self.collectionView reloadItemsAtIndexPaths:updateIndexPaths];
                    } completion:^(BOOL finished) {
                        [self.updatedObjects removeAllObjects];
                    }];
                }

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
