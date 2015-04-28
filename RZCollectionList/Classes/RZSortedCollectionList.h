//
//  RZSortedCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

/**
 *  RZSortedCollectionList takes an array of NSSortDescriptors and a source collection list. It uses the sort descriptors to sort the source list, and send all the appropriate change notifications.
 *  This is especially useful to automatically animate your changes in a table view or collection view, assuming that you are using RZCollectionListTableViewDataSource or RZCollectionListCollectionViewDataSource respectively.
 */
@interface RZSortedCollectionList : RZBaseCollectionList <RZCollectionList, RZCollectionListObserver>

/**
 *  The source collection list to sort.
 *  @note Must be passed in the initializer.
 */
@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;

/**
 *  The sort descriptors used to sort the source list.
 *  @note Must be passed in the initializer.
 */
@property (nonatomic, copy) NSArray *sortDescriptors;

/**
 *  An initializer for RZSortedCollectionList. Takes a source list and an array of NSSortDescriptors.
 *
 *  @param sourceList      The collection list you want to sort.
 *  @param sortDescriptors The NSSortDescriptors that will be used to sort the list.
 *
 *  @return An instance of RZSortedCollectionList.
 */
- (instancetype)initWithSourceList:(id<RZCollectionList>)sourceList sortDescriptors:(NSArray*)sortDescriptors;

@end
