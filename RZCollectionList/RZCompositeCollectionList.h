//
//  RZCompositeCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@interface RZCompositeCollectionList : NSObject <RZCollectionList, RZCollectionListObserver>

@property (nonatomic, copy) NSArray *sourceLists;

- (id)initWithSourceLists:(NSArray*)sourceLists;

@end
