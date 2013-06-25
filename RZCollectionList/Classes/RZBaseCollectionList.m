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
        _pendingSectionInsertNotifications  = [NSMutableArray arrayWithCapacity:8];
        _pendingSectionRemoveNotifications  = [NSMutableArray arrayWithCapacity:8];
        _pendingObjectInsertNotifications   = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectRemoveNotifications   = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectMoveNotifications     = [NSMutableArray arrayWithCapacity:16];
        _pendingObjectUpdateNotifications   = [NSMutableArray arrayWithCapacity:16];
        
    }
    return self;
}

#pragma mark - Protected Properties

- (RZObserverCollection*)collectionListObservers
{
    if (nil == _collectionListObservers)
    {
        _collectionListObservers = [[RZObserverCollection alloc] init];
    }
    
    return _collectionListObservers;
}

- (NSArray*)allPendingObjectNotifications
{
    NSMutableArray *allNotifications = [self.pendingObjectRemoveNotifications mutableCopy];
    [allNotifications addObjectsFromArray:self.pendingObjectInsertNotifications];
    [allNotifications addObjectsFromArray:self.pendingObjectMoveNotifications];
    [allNotifications addObjectsFromArray:self.pendingObjectUpdateNotifications];
    return allNotifications;
}

- (NSArray*)allPendingSectionNotifications
{
    NSMutableArray *allNotifications = [self.pendingSectionRemoveNotifications mutableCopy];
    [allNotifications addObjectsFromArray:self.pendingSectionInsertNotifications];
    return allNotifications;
}

#pragma mark - Protected Methods

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath type:(RZCollectionListChangeType)type
{
    RZCollectionListObjectNotification *notification = [[RZCollectionListObjectNotification alloc] init];
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
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type
{
    RZCollectionListSectionNotification *notification = [[RZCollectionListSectionNotification alloc] init];
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
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

//- (void)sortPendingNotifications
//{
//    // Remove Objects, sorted descending by index path
//    if (self.pendingObjectRemoveNotifications.count)
//    {
//       [self.pendingObjectRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:NO] ]];
//    }
//    
//    // Remove Sections, sorted descending by index
//    if (self.pendingSectionRemoveNotifications.count)
//    {
//        [self.pendingSectionRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:NO] ]];
//    }
//    
//    // Insert Sections, ascending by index
//    if (self.pendingSectionInsertNotifications.count)
//    {
//        [self.pendingSectionInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:YES] ]];
//    }
//    
//    // Insert Objects, ascending by index path
//    if (self.pendingObjectInsertNotifications.count)
//    {
//        [self.pendingObjectInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath" ascending:YES] ]];
//    }
//    
//    // Move Objects, ascending by destination index path
//    if (self.pendingObjectMoveNotifications.count)
//    {
//        [self.pendingObjectMoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath" ascending:YES] ]];
//    }
//}

- (void)sendWillChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZFilteredCollectionList Will Change");
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            // Making assumption that subclass implements protocol by casting
            [obj collectionListWillChangeContent:(id<RZCollectionList>)self];
        }
    }];
}

- (void)sendDidChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZFilteredCollectionList Did Change");
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            // Making assumption that subclass implements protocol by casting
            [obj collectionListDidChangeContent:(id<RZCollectionList>)self];
        }
    }];
}


- (void)sendAllPendingChangeNotifications
{
    // ---- Send out notifications
    
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectRemoveNotifications];
    }
    
    // Remove Sections, sorted descending by index
    if (self.pendingSectionRemoveNotifications.count)
    {
        [self.pendingSectionRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:NO] ]];
        [self sendSectionNotifications:self.pendingSectionRemoveNotifications];
    }
    
    // Insert Sections, ascending by index
    if (self.pendingSectionInsertNotifications.count)
    {
        [self.pendingSectionInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"sectionIndex" ascending:YES] ]];
        [self sendSectionNotifications:self.pendingSectionInsertNotifications];
    }
    
    // Insert Objects, ascending by index path
    if (self.pendingObjectInsertNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectInsertNotifications];
    }
    
    // Move Objects, ascending by destination index path
    if (self.pendingObjectMoveNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectMoveNotifications];
    }
    
    // Update Objects
    if (self.pendingObjectUpdateNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectUpdateNotifications];
    }
    
    // Reset the notifications, return them to reuse cache
    [self resetPendingNotifications];
}

- (void)sendSectionNotifications:(NSArray *)sectionNotifications
{
    [sectionNotifications enumerateObjectsUsingBlock:^(RZCollectionListSectionNotification *notification, NSUInteger idx, BOOL *stop) {
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                // Making assumption that subclass implements protocol by casting
                [obj collectionList:(id<RZCollectionList>)self didChangeSection:(id<RZCollectionListSectionInfo>)notification.sectionInfo atIndex:notification.sectionIndex forChangeType:notification.type];
            }
        }];
    }];
}

- (void)sendObjectNotifications:(NSArray *)objectNotifications
{
    [objectNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
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
    // remove notifications from containers
    [self.pendingSectionInsertNotifications   removeAllObjects];
    [self.pendingSectionRemoveNotifications   removeAllObjects];
    [self.pendingObjectInsertNotifications    removeAllObjects];
    [self.pendingObjectRemoveNotifications    removeAllObjects];
    [self.pendingObjectMoveNotifications      removeAllObjects];
    [self.pendingObjectUpdateNotifications    removeAllObjects];
}


@end