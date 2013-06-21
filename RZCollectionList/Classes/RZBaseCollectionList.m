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
        _pendingSectionInsertNotifications  = [NSMutableSet setWithCapacity:8];
        _pendingSectionRemoveNotifications   = [NSMutableSet setWithCapacity:8];
        _pendingObjectInsertNotifications   = [NSMutableSet setWithCapacity:16];
        _pendingObjectRemoveNotifications    = [NSMutableSet setWithCapacity:16];
        _pendingObjectMoveNotifications      = [NSMutableSet setWithCapacity:16];
        _pendingObjectUpdateNotifications    = [NSMutableSet setWithCapacity:16];
        
        _objectNotificationReuseCache  = [NSMutableSet setWithCapacity:kRZCollectionListNotificationReuseCacheMaxSize];
        _sectionNotificationReuseCache = [NSMutableSet setWithCapacity:kRZCollectionListNotificationReuseCacheMaxSize];
        
    }
    return self;
}

- (void)sendObjectAndSectionNotificationsToObservers
{
    // Default does nothing
}

- (void)resetPendingNotifications
{
    self.sourceObjectsBeforeUpdate                = nil;
    self.sourceSectionsInfoBeforeUpdateShallow    = nil;
    self.sourceSectionsInfoBeforeUpdateDeep       = nil;
    
    // clear objects going back into the cache
    [self.pendingSectionInsertNotifications   makeObjectsPerformSelector:@selector(clear)];
    [self.pendingSectionRemoveNotifications   makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectInsertNotifications    makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectRemoveNotifications    makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectMoveNotifications      makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectUpdateNotifications    makeObjectsPerformSelector:@selector(clear)];
    
    // move notifications back to reuse cache
    [self.sectionNotificationReuseCache unionSet:self.pendingSectionInsertNotifications];
    [self.sectionNotificationReuseCache unionSet:self.pendingSectionRemoveNotifications];
    [self.objectNotificationReuseCache  unionSet:self.pendingObjectInsertNotifications];
    [self.objectNotificationReuseCache  unionSet:self.pendingObjectRemoveNotifications];
    [self.objectNotificationReuseCache  unionSet:self.pendingObjectUpdateNotifications];
    [self.objectNotificationReuseCache  unionSet:self.pendingObjectMoveNotifications];
    
    // trim caches to max size if they got too big
    while (self.objectNotificationReuseCache.count > kRZCollectionListNotificationReuseCacheMaxSize){
        [self.objectNotificationReuseCache removeObject:[self.objectNotificationReuseCache anyObject]];
    }
    
    while (self.sectionNotificationReuseCache.count > kRZCollectionListNotificationReuseCacheMaxSize){
        [self.sectionNotificationReuseCache removeObject:[self.sectionNotificationReuseCache anyObject]];
    }
    
    // remove notifications from containers
    [self.pendingSectionInsertNotifications   removeAllObjects];
    [self.pendingSectionRemoveNotifications   removeAllObjects];
    [self.pendingObjectInsertNotifications    removeAllObjects];
    [self.pendingObjectRemoveNotifications    removeAllObjects];
    [self.pendingObjectMoveNotifications      removeAllObjects];
    [self.pendingObjectUpdateNotifications    removeAllObjects];
}

- (RZCollectionListObjectNotification*)dequeueReusableObjectNotification
{
    RZCollectionListObjectNotification *notification = nil;
    if (self.objectNotificationReuseCache.count > 0){
        
        // remove from beginning, re-add at end when done
        notification = [self.objectNotificationReuseCache anyObject];
        [self.objectNotificationReuseCache removeObject:notification];
    }
    else{
        notification = [[RZCollectionListObjectNotification alloc] init];
    }
    
    return notification;
}

- (RZCollectionListSectionNotification*)dequeueReusableSectionNotification
{
    RZCollectionListSectionNotification *notification = nil;
    if (self.sectionNotificationReuseCache.count > 0){
        
        // remove from beginning, re-add at end when done
        notification = [self.sectionNotificationReuseCache anyObject];
        [self.sectionNotificationReuseCache removeObject:notification];
    }
    else{
        notification = [[RZCollectionListSectionNotification alloc] init];
    }
    
    return notification;
}

@end