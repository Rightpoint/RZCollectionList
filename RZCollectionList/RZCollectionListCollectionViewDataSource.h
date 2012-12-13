//
//  RZCollectionListCollectionViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@protocol RZCollectionListCollectionViewDataSourceDelegate <NSObject>

@required
- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional
// The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

@interface RZCollectionListCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, strong, readonly) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readonly) UICollectionView *collectionView;

@property (nonatomic, weak) id<RZCollectionListCollectionViewDataSourceDelegate> delegate;

@property (nonatomic, assign, getter = shouldAnimateCollectionChanges) BOOL animateCollectionChanges; // Defaults to YES

- (id)initWithCollectionView:(UICollectionView*)collectionView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListCollectionViewDataSourceDelegate>)delegate;  // Calls beginObservingList before returning

// Begin/End CollectionList Observing
- (void)beginObservingList;     // Adds self as an observer of collectionList - Create a retain cycle
- (void)endObservingList;       // Removes self as an observer of collectionList - Breaks the retain cycle

@end
