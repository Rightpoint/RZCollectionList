//
//  RZCollectionListUIKitDataSourceAdapter.h
//  bhphoto
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

//! This class acts as an adapter for index-path-based notifications from collection lists to drive
//  a TableView or CollectionView with animated updates. Conversion of index paths is only necessary for
//  batch updates.

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@interface RZCollectionListUIKitDataSourceAdapter : NSObject <RZCollectionListObserver>

- (id)initWithObserver:(id<RZCollectionListObserver>)observer;
- (void)addObserver:(id<RZCollectionListObserver>)observer;
- (void)removeObserver:(id<RZCollectionListObserver>)observer;

@end
