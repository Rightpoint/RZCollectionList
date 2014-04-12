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

- (id)initWithSourceLists:(NSArray*)sourceLists;
- (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections; // Default is NO. If YES, will flatten list into one section.

- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex;

@end
