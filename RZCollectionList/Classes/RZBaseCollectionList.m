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

- (void)sendObjectAndSectionNotificationsToObservers:(NSArray*)observers
{
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
        NSArray *sortedRemoves = [self.pendingObjectRemoveNotifications sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"indexPath.section" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"indexPath.row" ascending:NO]]];
        [self sendObjectNotifications:sortedRemoves toObservers:observers];
    }
    
    // Remove Sections, sorted descending by index
    if (self.pendingSectionRemoveNotifications.count)
    {
        NSArray *sortedRemoves = [self.pendingSectionRemoveNotifications sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:NO] ]];
        [self sendSectionNotifications:sortedRemoves toObservers:observers];
    }
    
    // Insert Sections, ascending by index
    if (self.pendingSectionInsertNotifications.count)
    {
        NSArray *sortedInserts = [self.pendingSectionInsertNotifications sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:YES] ]];
        [self sendSectionNotifications:sortedInserts toObservers:observers];
    }
    
    // Insert Objects, ascending by index path
    if (self.pendingObjectInsertNotifications.count)
    {
        NSArray *sortedInserts = [self.pendingObjectInsertNotifications sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.section" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.row" ascending:YES]]];
        [self sendObjectNotifications:sortedInserts toObservers:observers];
    }
    
    // Move Objects, ascending by destination index path
    if (self.pendingObjectMoveNotifications.count)
    {
        NSArray *sortedMoves = [self.pendingObjectMoveNotifications sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.section" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.row" ascending:YES]]];
        [self sendObjectNotifications:sortedMoves toObservers:observers];
    }
    
    // Update Objects
    if (self.pendingObjectUpdateNotifications.count)
    {
        [self sendObjectNotifications:[self.pendingObjectUpdateNotifications allObjects] toObservers:observers];
    }
    
    // Reset the notifications, return them to reuse cache
    [self resetPendingNotifications];
}

- (void)sendSectionNotifications:(NSArray *)sectionNotifications toObservers:(NSArray*)observers
{
    [sectionNotifications enumerateObjectsUsingBlock:^(RZCollectionListSectionNotification *notification, NSUInteger idx, BOOL *stop) {
        [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                // Making assumption that subclass implements protocol by casting
                [obj collectionList:(id<RZCollectionList>)self didChangeSection:(id<RZCollectionListSectionInfo>)notification.sectionInfo atIndex:notification.sectionIndex forChangeType:notification.type];
            }
        }];
    }];
}

- (void)sendObjectNotifications:(NSArray *)objectNotifications toObservers:(NSArray*)observers
{
    [objectNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                // Making assumption that subclass implements protocol by casting
                [obj collectionList:(id<RZCollectionList>)self didChangeObject:notification.object atIndexPath:notification.indexPath forChangeType:notification.type newIndexPath:notification.nuIndexPath];
            }
        }];
    }];
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