//
//  RZFilteredCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/12/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

/**
 *  Create an RZFilteredCollectionList to subset a current list into its own object.
 */
@interface RZFilteredCollectionList : RZBaseCollectionList <RZCollectionListObserver>

/**
 *  An instance of id<RZCollectionList> that you want to filter.
 */
@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;

/**
 *  An instance of NSPredicate used to define the filter on your source list.
 */
@property (nonatomic, strong) NSPredicate *predicate;

/**
 *  An initializer for RZFilteredCollectionList. Takes a source list and a predicate.
 *  @note private BOOL filterOutEmptySections defaults to YES. Use - (id)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate filterOutEmptySections:(BOOL)filterOutEmptySections if you want to set this property to NO.
 *
 *  @param sourceList A pre-existing instance of id<RZCollectionList> that you want to filter.
 *  @param predicate  An instance of NSPredicate used to define the filter on your source list.
 *
 *  @return An instance of RZFilteredCollectionList.
 */
- (instancetype)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate;

/**
 *  An initializer for RZFilteredCollectionList. Takes a source list, a predicate, and a boolean to determine whether or not to filter out empty sections.
 *
 *  @param sourceList             A pre-existing instance of id<RZCollectionList> that you want to filter.
 *  @param predicate              An instance of NSPredicate used to define the filter on your source list.
 *  @param filterOutEmptySections Determines whether or not empty sections are included in the filtered list.
 *
 *  @return An instance of RZFilteredCollectionList.
 */
- (instancetype)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate filterOutEmptySections:(BOOL)filterOutEmptySections; // defaults to YES, will hide empty sections

@end
