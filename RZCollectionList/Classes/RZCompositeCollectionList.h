//
//  RZCompositeCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

@interface RZCompositeCollectionList : RZBaseCollectionList <RZCollectionList, RZCollectionListObserver>

// Currently readonly.
// TODO: need to implement in-place source list array update.
@property (nonatomic, readonly, copy) NSArray *sourceLists;

- (id)initWithSourceLists:(NSArray*)sourceLists;
- (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections; // Default is NO. If YES, will flatten list into one section.

- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex;

@end
