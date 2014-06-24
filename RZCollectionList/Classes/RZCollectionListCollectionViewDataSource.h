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

//! Implement this to immediately update a cell's contents as part of a batch update, as opposed to reloading after a batch animatino
/*!
    The indexPath parameter is the index path of the object in the collection list at the time this method is called, NOT the index path of the cell being updated!!
 */
- (void)collectionView:(UICollectionView*)collectionView updateCell:(UICollectionViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

@interface RZCollectionListCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, weak, readonly) UICollectionView *collectionView;

/**
 *  The collection list driving this data source. May safely be changed or set to nil after initialization.
 */
@property (nonatomic, strong) id<RZCollectionList> collectionList;

@property (nonatomic, weak)   id<RZCollectionListCollectionViewDataSourceDelegate> delegate;

@property (nonatomic, assign, getter = shouldAnimateCollectionChanges) BOOL animateCollectionChanges; // Defaults to YES
@property (nonatomic, assign, getter = shouldUseBatchUpdating) BOOL useBatchUpdating; // Defaults to YES

/**
 *  Init with a collection view, collection list, and delegate.
 *
 *  @param collectionView   The collection view for which this instance will be the data source. Must not be nil.
 *  @param collectionList   The list to use as the source for the object data driving this data source. May safely be set/changed later.
 *  @param delegate         A required delegate for providing collection view cells.
 *                          If not set, the table view will throw an exception when a cell is requested. 
 *
 *  @return An initialized collection view data source instance.
 */
- (id)initWithCollectionView:(UICollectionView*)collectionView
              collectionList:(id<RZCollectionList>)collectionList
                    delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;

@end
