//
//  RZBaseCollectionList_Private.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseCollectionList.h"

// Max number of notifications to keep around for reuse.
// Exceeding this number in a single batch update will cause new allocations.
// Left fairly generous since notification objects are pretty small.
#define kRZCollectionListNotificationReuseCacheMaxSize 128

@interface RZBaseCollectionList ()

// batch update object cache containers

// these should be used to cache contents of the current collection or
// an observed collection prior to mutating the internal state
@property (nonatomic, strong) NSArray *sourceSectionsInfoBeforeUpdateDeep;       // deep-copies - range/offset will not change during update
@property (nonatomic, strong) NSArray *sourceSectionsInfoBeforeUpdateShallow;    // shallow-copies - use only for index lookup after update
@property (nonatomic, strong) NSArray *sourceObjectsBeforeUpdate;

// these should be used to cache section/object changes during an update
@property (nonatomic, strong) NSMutableSet *sectionsInsertedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *sectionsRemovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsInsertedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsRemovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsMovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsUpdatedDuringUpdate;


- (void)sendObjectAndSectionNotificationsToObservers; // default does nothing
- (void)clearCachedCollectionInfo;

@end
