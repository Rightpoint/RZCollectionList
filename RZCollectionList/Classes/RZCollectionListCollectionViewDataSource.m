//
//  RZCollectionListCollectionViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListCollectionViewDataSource.h"
#import <UIKit/UITableView.h>

typedef void(^RZCollectionListCollectionViewBatchUpdateBlock)(void);

@interface RZCollectionListCollectionViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, weak, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *batchUpdates;
@property (nonatomic, strong) NSMutableArray *insertedSectionIndexes;

@property (nonatomic, assign) BOOL delegateImplementsInPlaceUpdate;
@property (nonatomic, assign) BOOL reloadAfterAnimation;

@end

@implementation RZCollectionListCollectionViewDataSource

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate
{
    NSParameterAssert(collectionView);
    
    if ((self = [super init]))
    {
        self.delegate = delegate;
        self.collectionView = collectionView;
        
        self.animateCollectionChanges = YES;
        self.useBatchUpdating = YES;
        
        collectionView.dataSource = self;
        
        self.collectionList = collectionList;
    }
    
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self];
}

- (void)setCollectionList:(id<RZCollectionList>)collectionList
{
    if (collectionList != _collectionList)
    {
        if (nil != _collectionList)
        {
            [_collectionList removeCollectionListObserver:self];
            _collectionList.delegate = nil;
        }
        
        _collectionList = collectionList;
        
        if (nil != collectionList)
        {
            [collectionList addCollectionListObserver:self];
            collectionList.delegate = self;
        }
        
        [self.collectionView reloadData];
    }
}

- (void)setDelegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate
{
    _delegate = delegate;
    self.delegateImplementsInPlaceUpdate = [delegate respondsToSelector:@selector(collectionView:updateCell:forObject:atIndexPath:)];
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

            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            if (cell != nil){
                
                if (self.useBatchUpdating){
                
                    // If the delegate implements the update method, update right now. Otherwise delay.
                    if (self.delegateImplementsInPlaceUpdate)
                    {
                        [self.delegate collectionView:self.collectionView updateCell:cell forObject:object atIndexPath:newIndexPath];
                    }
                    else
                    {
                        self.reloadAfterAnimation = YES;
                    }
                }
                else
                {
                    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                }
            }

        }
        else
        {
            
            BOOL shouldChangeObject = YES;
            
            if (type == RZCollectionListChangeInsert)
            {
                shouldChangeObject = ![self.insertedSectionIndexes containsObject:@(newIndexPath.section)];
            }
            
            if (shouldChangeObject)
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
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    if (self.animateCollectionChanges)
    {
        if (type == RZCollectionListChangeInsert)
        {
            [self.insertedSectionIndexes addObject:@(sectionIndex)];
        }
        
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
            self.reloadAfterAnimation = NO;
            self.batchUpdates = [NSMutableArray array];
            self.insertedSectionIndexes = [NSMutableArray array];
        }
    }
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    // If collection view isn't on screen yet, don't animate anything - it doesn't like that.
    if (self.animateCollectionChanges  && self.collectionView.window != nil)
    {
        if (self.useBatchUpdating)
        {
            if (self.batchUpdates.count > 0)
            {                
                [self.collectionView performBatchUpdates:^{
                    
                    [self.batchUpdates enumerateObjectsUsingBlock:^(RZCollectionListCollectionViewBatchUpdateBlock changeBlock, NSUInteger idx, BOOL *stop) {
                        changeBlock();
                    }];
                    
                } completion:^(BOOL finished) {
                    
                    if (self.reloadAfterAnimation)
                    {
                        [self.collectionView reloadData];
                        self.reloadAfterAnimation = NO;
                    }
                    self.batchUpdates = nil;
                    
                }];

            }
            
            self.insertedSectionIndexes = nil;
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
