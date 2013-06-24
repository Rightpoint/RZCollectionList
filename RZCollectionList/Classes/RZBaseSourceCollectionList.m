//
//  RZBaseSourceCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseSourceCollectionList.h"
#import "RZBaseSourceCollectionList_Private.h"

@interface RZBaseSourceCollectionList ()

@property (nonatomic, strong) NSMutableSet *sectionNotificationReuseCache;
@property (nonatomic, strong) NSMutableSet *objectNotificationReuseCache;

// TODO: These may not be necessary
- (RZCollectionListObjectNotification*)dequeueReusableObjectNotification;
- (RZCollectionListSectionNotification*)dequeueReusableSectionNotification;

@end

@implementation RZBaseSourceCollectionList

- (id)init
{
    self = [super init];
    if (self) {
        
        // allocate the mutable containers
        _pendingSectionInsertNotifications  = [NSMutableArray arrayWithCapacity:8];
        _pendingSectionRemoveNotifications  = [NSMutableArray arrayWithCapacity:8];
        _pendingObjectInsertNotifications   = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectRemoveNotifications   = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectMoveNotifications     = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectUpdateNotifications   = [NSMutableArray arrayWithCapacity:16];
        
        _objectNotificationReuseCache  = [NSMutableSet setWithCapacity:kRZCollectionListNotificationReuseCacheMaxSize];
        _sectionNotificationReuseCache = [NSMutableSet setWithCapacity:kRZCollectionListNotificationReuseCacheMaxSize];
        
    }
    return self;
}

- (void)enqueueObjectNotificationWithObject:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath type:(RZCollectionListChangeType)type
{
    RZCollectionListObjectNotification *notification = [self dequeueReusableObjectNotification];
    notification.object = object;
    notification.indexPath = indexPath;
    notification.nuIndexPath = newIndexPath;
    notification.type = type;
    
    switch (type) {
        case RZCollectionListChangeDelete:
            [self.pendingObjectRemoveNotifications addObject:notification];
            break;
            
        case RZCollectionListChangeInsert:
            [self.pendingObjectInsertNotifications addObject:notification];
            break;
            
        case RZCollectionListChangeMove:
            [self.pendingObjectMoveNotifications addObject:notification];
            break;
            
        case RZCollectionListChangeUpdate:
            [self.pendingObjectUpdateNotifications addObject:notification];
            break;
            
        default:
            break;
    }
}

- (void)enqueueSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type
{
    RZCollectionListSectionNotification *notification = [self dequeueReusableSectionNotification];
    notification.sectionInfo = sectionInfo;
    notification.sectionIndex = sectionIndex;
    notification.type = type;
    
    switch (type) {
        case RZCollectionListChangeDelete:
            [self.pendingSectionRemoveNotifications addObject:notification];
            break;
            
        case RZCollectionListChangeInsert:
            [self.pendingSectionInsertNotifications addObject:notification];
            break;
            
        default:
            break;
    }
}

- (void)sortPendingNotifications
{
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
       [self.pendingObjectRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"indexPath.section" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"indexPath.row" ascending:NO]]];
    }
    
    // Remove Sections, sorted descending by index
    if (self.pendingSectionRemoveNotifications.count)
    {
        [self.pendingSectionRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:NO] ]];
    }
    
    // Insert Sections, ascending by index
    if (self.pendingSectionInsertNotifications.count)
    {
        [self.pendingSectionInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:YES] ]];
    }
    
    // Insert Objects, ascending by index path
    if (self.pendingObjectInsertNotifications.count)
    {
        [self.pendingObjectInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.section" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.row" ascending:YES]]];
    }
    
    // Move Objects, ascending by destination index path
    if (self.pendingObjectMoveNotifications.count)
    {
        [self.pendingObjectMoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.section" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath.row" ascending:YES]]];
    }
}

- (void)sendPendingNotificationsToObservers:(NSArray*)observers
{
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectRemoveNotifications toObservers:observers];
    }
    
    // Remove Sections, sorted descending by index
    if (self.pendingSectionRemoveNotifications.count)
    {
        [self sendSectionNotifications:self.pendingSectionRemoveNotifications toObservers:observers];
    }
    
    // Insert Sections, ascending by index
    if (self.pendingSectionInsertNotifications.count)
    {
        [self sendSectionNotifications:self.pendingSectionInsertNotifications toObservers:observers];
    }
    
    // Insert Objects, ascending by index path
    if (self.pendingObjectInsertNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectInsertNotifications toObservers:observers];
    }
    
    // Move Objects, ascending by destination index path
    if (self.pendingObjectMoveNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectMoveNotifications toObservers:observers];
    }
    
    // Update Objects
    if (self.pendingObjectUpdateNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectUpdateNotifications toObservers:observers];
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
    
    // clear objects going back into the cache
    [self.pendingSectionInsertNotifications   makeObjectsPerformSelector:@selector(clear)];
    [self.pendingSectionRemoveNotifications   makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectInsertNotifications    makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectRemoveNotifications    makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectMoveNotifications      makeObjectsPerformSelector:@selector(clear)];
    [self.pendingObjectUpdateNotifications    makeObjectsPerformSelector:@selector(clear)];
    
    // move notifications back to reuse cache
    [self.sectionNotificationReuseCache addObjectsFromArray:self.pendingSectionInsertNotifications];
    [self.sectionNotificationReuseCache addObjectsFromArray:self.pendingSectionRemoveNotifications];
    [self.objectNotificationReuseCache  addObjectsFromArray:self.pendingObjectInsertNotifications];
    [self.objectNotificationReuseCache  addObjectsFromArray:self.pendingObjectRemoveNotifications];
    [self.objectNotificationReuseCache  addObjectsFromArray:self.pendingObjectUpdateNotifications];
    [self.objectNotificationReuseCache  addObjectsFromArray:self.pendingObjectMoveNotifications];
    
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