//
//  RZCollectionListCollectionViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListCollectionViewDataSource.h"

@interface RZCollectionListCollectionViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, strong, readwrite) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readwrite) UICollectionView *collectionView;

@end

@implementation RZCollectionListCollectionViewDataSource

- (id)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate
{
    if ((self = [super init]))
    {
        self.collectionList = collectionList;
        self.delegate = delegate;
        self.collectionView = collectionView;
        
        self.animateCollectionChanges = YES;
        [self.collectionList addCollectionListObserver:self];
        collectionList.delegate = self;
        
        collectionView.dataSource = self;
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
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    if (self.animateCollectionChanges)
    {
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
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.animateCollectionChanges)
    {
        // TODO - collect updates for batch updating.
    }
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.animateCollectionChanges)
    {
        // TODO - execute batch updates using performBatchUpdates:completion:
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
