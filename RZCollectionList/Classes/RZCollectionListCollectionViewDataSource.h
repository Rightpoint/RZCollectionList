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

/**
 *  Use this callback instead of - (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
 *  @warning @b Must return a valid UICollectionViewCell from -dequeueReusableCellWithReuseIdentifier:forIndexPath:
 *
 *  @param collectionView The collection view associated with this data source.
 *  @param object         Use this object to populate your cell.
 *  @param indexPath      The index path of the object in your id<RZCollectionList>.
 *
 *  @return               A configured supplementary view object. You must not return nil from this method.
 */
- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

/**
 *  Implement this to immediately update a cell's contents as part of a batch update, as opposed to reloading after a batch animation.
 *  @warning The indexPath parameter is the index path of the object in the collection list at the time this method is called, @b NOT the index path of the cell
 *  being updated!
 *
 *  @param collectionView The collection view associated with this data source.
 *  @param cell           The cell to be updated.
 *  @param object         The object used to populate the cell.
 *  @param indexPath      The index path of the object being updated
 */
- (void)collectionView:(UICollectionView*)collectionView updateCell:(UICollectionViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:

/**
 *  Use this callback instead of - (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
 *  @warning The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
 *
 *  @param collectionView The collection view associated with this data source.
 *  @param kind           The kind of supplementary view to provide. The value of this string is defined by the layout object that supports the supplementary view.
 *  @param indexPath      The index path that specifies the location of the new supplementary view.
 *
 *  @return A configured supplementary view object. You must not return nil from this method.
 */
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

/**
 *  Use RZCollectionListCollectionViewDataSource when using an id<RZCollectionList> as the data for a UICollectionView. You initialize an instance of this class, usually saved as a property on your View Controller, with an initialized id<RZCollectionList>.
    For example:
 
    @code
 self.collectionList = [[RZArrayCollectionList alloc] initWithArray:@[@"This", @"CollectionView", @"Will", @"Be", @"Awesome!"]  sectionNameKeyPath:nil];
 self.dataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
 collectionList:self.self.collectionList
 delegate:self];
 */
@interface RZCollectionListCollectionViewDataSource : NSObject <UICollectionViewDataSource>

/**
 *  The collection list used as the data source for _collectionView.
 *  @warning Can only be set during initialization with the constructor method: - (id)initWithCollectionView:(UICollectionView*)collectionView 
 *  collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;
 */
@property (nonatomic, strong, readonly) id<RZCollectionList> collectionList;

/**
 *  The collection view associated with this data source.
 *  @warning Can only be set during initialization with the constructor method: - (id)initWithCollectionView:(UICollectionView*)collectionView
 *  collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;
 */
@property (nonatomic, weak, readonly) UICollectionView *collectionView;

/**
 *  The delegate for this data source.
 */
@property (nonatomic, weak) id<RZCollectionListCollectionViewDataSourceDelegate> delegate;

/**
 *  Animate any changes to _collectionList
 */
@property (nonatomic, assign, getter = shouldAnimateCollectionChanges) BOOL animateCollectionChanges; // Defaults to YES

/**
 *  Allow batch updating of _collectionList. Helps with animations when multiple changes occur in a short time span.
 */
@property (nonatomic, assign, getter = shouldUseBatchUpdating) BOOL useBatchUpdating; // Defaults to YES

/**
 *  Initializer for RZCollectionListCollectionViewDataSourceDelegate instance.
 *
 *  @param collectionView The collection view to be updated by this RZCollectionListCollectionViewDataSourceDelegate instance. There can only be one collection view per RZCollectionListCollectionViewDataSourceDelegate instance.
 *  @param collectionList the collection list used to update the supplied collection view. There can only be one collection list per RZCollectionListCollectionViewDataSourceDelegate instance. Be sure to use an RZCompositeCollectionList when your data consists of multiple lists.
 *  @param delegate       An object that conforms to the RZCollectionListCollectionViewDataSourceDelegate protocol. This should never be nil.
 *
 *  @return An instance of RZCollectionListCollectionViewDataSourceDelegate. It's usually helpful to keep this as a property.
 */
- (id)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;

@end
