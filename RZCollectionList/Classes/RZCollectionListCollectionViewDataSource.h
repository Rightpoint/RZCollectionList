//
//  RZCollectionListCollectionViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"

/**
 *  An object that adopts the RZCollectionListCollectionViewDataSourceDelegate protocol is responsible for providing the data and views required by an
 *  RZCollectionListCollectionViewDataSource instance for a UICollectionView. It also handles the creation and configuration of cells and supplementary views
 *  used by the collection view to display the data in the supplied id<RZCollecitonList>.
 */
@protocol RZCollectionListCollectionViewDataSourceDelegate <NSObject>

@required

/**
 *  Callback to provide a cell to the data source for a particular object.
 *
 *  @warning @b Must return a valid UICollectionViewCell from @p -dequeueReusableCellWithReuseIdentifier:forIndexPath:
 *
 *  @param collectionView The collection view associated with this data source.
 *  @param object         Use this object to populate your cell.
 *  @param indexPath      The index path of the object in the collection list.
 *
 *  @return A configured UICollectionViewCell object. You must not return nil from this method.
 */
- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

/**
 *  Implement this to immediately update a cell's contents as part of a batch update, as opposed to reloading after a batch animation.
 *  
 *  @warning The indexPath parameter is the index path of the object in the collection list at the time this method is called, @b NOT the index path of the
 *  cell being updated!
 *
 *  @param collectionView The collection view associated with this data source.
 *  @param cell           The cell to be updated.
 *  @param object         The object used to populate the cell.
 *  @param indexPath      The index path of the cell being updated
 */
- (void)collectionView:(UICollectionView*)collectionView updateCell:(UICollectionViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 *  Optional callback to provide a supplementary view as requested by the data source for a particular indexPath.
 *
 *  @warning The view that is returned must be retrieved from a call to @p -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
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
 *  Use RZCollectionListCollectionViewDataSource when using a collection list as the data for a UICollectionView. You initialize an instance of this
 *  class, usually saved as a property on your View Controller, with a collection view, collection list, and (required) delegate.
 *
 */
@interface RZCollectionListCollectionViewDataSource : NSObject <UICollectionViewDataSource>

/**
 *  The collection list used as the data source for the collection view.
 *  May safely be changed or set to nil after initialization.
 */
@property (nonatomic, strong) id<RZCollectionList> collectionList;

/**
 *  The collection view associated with this data source.
 *  @note Can only be set during initialization.
 */
@property (nonatomic, weak, readonly) UICollectionView *collectionView;

/**
 *  The delegate for this data source.
 */
@property (nonatomic, weak) id<RZCollectionListCollectionViewDataSourceDelegate> delegate;

/**
 *  Whether to animate any changes to the collection list, or reload in place.
 *  @note Defaults to YES.
 */
@property (nonatomic, assign, getter = shouldAnimateCollectionChanges) BOOL animateCollectionChanges;

/**
 *  Whether to allow batch updating of the collection list. Helps with animations when multiple changes occur in a short time span.
 *  @note Defaults to YES.
 */
@property (nonatomic, assign, getter = shouldUseBatchUpdating) BOOL useBatchUpdating;

/**
 *  Initializer for an RZCollectionListCollectionViewDataSourceDelegate instance.
 *
 *  @param collectionView   The collection view to be updated by this RZCollectionListCollectionViewDataSourceDelegate instance.
 *  @param collectionList   The collection list used to update the collection view.
 *  @param delegate         An object that conforms to the RZCollectionListCollectionViewDataSourceDelegate protocol. This should never be nil.
 *  
 *  @note There can only be one collection list per RZCollectionListCollectionViewDataSourceDelegate instance. 
 *        Use an RZCompositeCollectionList when your data consists of multiple lists.
 *
 *  @return An instance of RZCollectionListCollectionViewDataSourceDelegate. It's usually helpful to keep this as a property.
 */
- (id)initWithCollectionView:(UICollectionView*)collectionView
              collectionList:(id<RZCollectionList>)collectionList
                    delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;

@end
