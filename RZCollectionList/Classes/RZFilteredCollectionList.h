//
//  RZFilteredCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/12/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZBaseCollectionList.h"

@interface RZFilteredCollectionList : RZBaseCollectionList <RZCollectionList, RZCollectionListObserver>

@property (nonatomic, strong, readonly) id<RZCollectionList> sourceList;
@property (nonatomic, strong) NSPredicate *predicate;

- (id)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate;
- (id)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate allowEmptySections:(BOOL)allowEmptySections; // defaults to NO, will hide empty sections

@end
