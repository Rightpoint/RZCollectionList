//
//  RZSortedCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@interface RZSortedCollectionList : NSObject <RZCollectionList, RZCollectionListObserver>

@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;
@property (nonatomic, copy) NSArray *sortDescriptors;

- (id)initWithSourceList:(id<RZCollectionList>)sourceList sortDescriptors:(NSArray*)sortDescriptors;

@end
