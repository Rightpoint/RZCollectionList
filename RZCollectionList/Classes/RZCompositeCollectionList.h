//
//  RZCompositeCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

/**
 *  RZCompositeCollectionList is a "list of lists." All you need to do to properly use RZCompositeCollectionList is to create one or 
 *  more instances of id<RZCollectionList>.
 */
@interface RZCompositeCollectionList : RZBaseCollectionList <RZCollectionList, RZCollectionListObserver>

/**
 *  An array of the lists in an instance of RZCompositeCollectionList.
 *  @note Currently read-only.
 *  @todo Need to implement in-place source list array update.
 */
@property (nonatomic, readonly, copy) NSArray *sourceLists;

/**
 *  Initializer for an instance of RZCompositeCollectionList. You must provide one or more @b initialized source id<RZCollectionList> instances. 
 *  For example, you may have an RZFetchedCollectionList and an RZArrayCollectionList that you want to combine as the data source for a UICollectionView.
 *
 *  @note BOOL ignoresSections will default to NO with this initializer. Use - (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections, passing YES, if you wish to initialize this list as one section.
 *
 *  @param sourceLists The id<RZCollectionList> lists that will comprise the returned instance of RZCompositeCollectionList.
 *
 *  @return An instance of RZCompositeCollectionList.
 */
- (id)initWithSourceLists:(NSArray*)sourceLists;

/**
 *  Initializer for an instance of RZCompositeCollectionList. You must provide one or more @b initialized source id<RZCollectionList> instances.
 *  For example, you may have an RZFetchedCollectionList and an RZArrayCollectionList that you want to combine as the data source for a UICollectionView.
 *  You also must provide a Boolean to represent whether you want this list to use the sections of the source lists, or to have all the data in a single section.
 *
 *  @param sourceLists    The id<RZCollectionList> lists that will comprise the returned instance of RZCompositeCollectionList.
 *  @param ignoreSections YES treat all items as if they are in one section, NO will maintain the original sections of the source lists. Specifying NO for ignoreSections will not affect the sections of the source lists already in place - The RZCompositeCollectionList will just ignore them.
 *
 *  @return An instance of RZCompositeCollectionList.
 */
- (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections; // Default is NO. If YES, will flatten list into one section.

/**
 *  Returns the list at the specified section in the RZCompositeCollectionList instance. This will work even if _ignoreSections is set to YES.
 *
 *  @param sectionIndex The index of the section within the instance of RZCompositeCollectionList.
 *
 *  @return One of the source lists of this instance of RZCompositeCollectionList or nil if none exist at that index.
 */
- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex;

@end
