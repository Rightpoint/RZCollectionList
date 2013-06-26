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

@property (nonatomic, copy) NSArray *sourceLists;

- (id)initWithSourceLists:(NSArray*)sourceLists;
- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex;

@end
