//
//  RZFilteredCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/12/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@interface RZFilteredCollectionList : NSObject <RZCollectionList, RZCollectionListObserver>

@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;
@property (nonatomic, strong, readonly) NSPredicate *predicate;

- (id)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate;

@end
