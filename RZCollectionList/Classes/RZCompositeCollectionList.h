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

- (id)initWithSourceLists:(NSArray*)sourceLists;
- (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections; // Default is NO. If YES, will flatten list into one section.

- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex;

@end
