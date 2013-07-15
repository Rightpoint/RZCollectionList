//
//  RZCollectionListCollectionViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"

@protocol RZCollectionListCollectionViewDataSourceDelegate <NSObject>

@required
- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

//! Implement this to immediately update a cell's contents as part of a batch update, as opposed to a parallel animation (which can look strange)
/*!
    The indexPath parameter is the index path of the object in the collection list at the time this method is called, NOT the index path of the cell being updated.
 */
- (void)collectionView:(UICollectionView*)collectionView updateCell:(UICollectionViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

@interface RZCollectionListCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, strong, readonly) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readonly) UICollectionView *collectionView;

@property (nonatomic, weak) id<RZCollectionListCollectionViewDataSourceDelegate> delegate;

@property (nonatomic, assign, getter = shouldAnimateCollectionChanges) BOOL animateCollectionChanges; // Defaults to YES
@property (nonatomic, assign, getter = shouldUseBatchUpdating) BOOL useBatchUpdating; // Defaults to YES

- (id)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;

@end
