//
//  RZCollectionList.h
//  RZCollectionList
//
//  Created by Nick Donaldson on 06/21/13.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionList.h"

@implementation RZBaseCollectionList

- (id)init
{
    self = [super init];
    if (self) {
        
        // allocate the mutable containers
        _sectionsInsertedDuringUpdate  = [NSMutableSet setWithCapacity:8];
        _sectionsRemovedDuringUpdate   = [NSMutableSet setWithCapacity:8];
        _objectsInsertedDuringUpdate   = [NSMutableSet setWithCapacity:16];
        _objectsRemovedDuringUpdate    = [NSMutableSet setWithCapacity:16];
        _objectsMovedDuringUpdate      = [NSMutableSet setWithCapacity:16];
        _objectsUpdatedDuringUpdate    = [NSMutableSet setWithCapacity:16];
        
    }
    return self;
}

- (void)clearCachedCollectionInfo
{
    self.objectsBeforeUpdate                = nil;
    self.sectionsInfoBeforeUpdateShallow    = nil;
    self.sectionsInfoBeforeUpdateDeep       = nil;
    
    [self.sectionsInsertedDuringUpdate  removeAllObjects];
    [self.sectionsRemovedDuringUpdate   removeAllObjects];
    [self.objectsInsertedDuringUpdate   removeAllObjects];
    [self.objectsRemovedDuringUpdate    removeAllObjects];
    [self.objectsMovedDuringUpdate      removeAllObjects];
    [self.objectsUpdatedDuringUpdate    removeAllObjects];
}

@end