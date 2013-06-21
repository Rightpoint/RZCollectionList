//
//  RZBaseCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseCollectionList.h"
#import "RZBaseCollectionList_Private.h"

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
    self.sourceObjectsBeforeUpdate                = nil;
    self.sourceSectionsInfoBeforeUpdateShallow    = nil;
    self.sourceSectionsInfoBeforeUpdateDeep       = nil;
    
    [self.sectionsInsertedDuringUpdate  removeAllObjects];
    [self.sectionsRemovedDuringUpdate   removeAllObjects];
    [self.objectsInsertedDuringUpdate   removeAllObjects];
    [self.objectsRemovedDuringUpdate    removeAllObjects];
    [self.objectsMovedDuringUpdate      removeAllObjects];
    [self.objectsUpdatedDuringUpdate    removeAllObjects];
}

- (void)sendObjectAndSectionNotificationsToObservers
{
    // Default does nothing
}

@end