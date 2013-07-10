//
//  RZSortedCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

@interface RZSortedCollectionList : RZBaseCollectionList <RZCollectionList, RZCollectionListObserver>

@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;
@property (nonatomic, copy) NSArray *sortDescriptors;

- (id)initWithSourceList:(id<RZCollectionList>)sourceList sortDescriptors:(NSArray*)sortDescriptors;

@end
