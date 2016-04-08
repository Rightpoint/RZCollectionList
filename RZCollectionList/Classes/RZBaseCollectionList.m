//
//  RZBaseCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseCollectionList.h"
#import "RZBaseCollectionList_Private.h"

static NSString * const RZCollectionListMissingProtocolMethodException = @"RZCollectionListMissingProtocolMethodException";

@interface RZBaseCollectionList ()

- (NSException*)missingProtocolMethodExceptionWithSelector:(SEL)selector;

@end

@implementation RZBaseCollectionList

@synthesize delegate = _delegate;

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

// ------ Lazy-loaded collections ------

- (NSMutableArray*)pendingSectionInsertNotifications
{
    if (nil == _pendingSectionInsertNotifications)
    {
        _pendingSectionInsertNotifications = [NSMutableArray arrayWithCapacity:8];
    }
    return _pendingSectionInsertNotifications;
}

- (NSMutableArray*)pendingSectionRemoveNotifications
{
    if (nil == _pendingSectionRemoveNotifications)
    {
        _pendingSectionRemoveNotifications = [NSMutableArray arrayWithCapacity:8];
    }
    return _pendingSectionRemoveNotifications;
}

- (NSMutableArray*)pendingObjectInsertNotifications
{
    if (nil == _pendingObjectInsertNotifications)
    {
        _pendingObjectInsertNotifications = [NSMutableArray arrayWithCapacity:16];
    }
    return _pendingObjectInsertNotifications;
}

- (NSMutableArray*)pendingObjectRemoveNotifications
{
    if (nil == _pendingObjectRemoveNotifications)
    {
        _pendingObjectRemoveNotifications = [NSMutableArray arrayWithCapacity:16];
    }
    return _pendingObjectRemoveNotifications;
}

- (NSMutableArray*)pendingObjectMoveNotifications
{
    if (nil == _pendingObjectMoveNotifications)
    {
        _pendingObjectMoveNotifications = [NSMutableArray arrayWithCapacity:16];
    }
    return _pendingObjectMoveNotifications;
}

- (NSMutableArray*)pendingObjectUpdateNotifications
{
    if (nil == _pendingObjectUpdateNotifications)
    {
        _pendingObjectUpdateNotifications = [NSMutableArray arrayWithCapacity:16];
    }
    return _pendingObjectUpdateNotifications;
}

#pragma mark - Protected Methods

- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath type:(RZCollectionListChangeType)type
{
    [self cacheObjectNotificationWithObject:object indexPath:indexPath newIndexPath:newIndexPath type:type sourceList:nil];
}

- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list
{
    RZCollectionListObjectNotification *notification = [[RZCollectionListObjectNotification alloc] init];
    notification.object = object;
    notification.indexPath = indexPath;
    notification.nuIndexPath = newIndexPath;
    notification.type = type;
    notification.sourceList = list;
    
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
    [self cacheSectionNotificationWithSectionInfo:sectionInfo sectionIndex:sectionIndex type:type sourceList:nil];
}

- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list
{
    RZCollectionListSectionNotification *notification = [[RZCollectionListSectionNotification alloc] init];
    notification.sectionInfo = sectionInfo;
    notification.sectionIndex = sectionIndex;
    notification.type = type;
    notification.sourceList = list;
    
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


- (void)sendWillChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"%@ Will Change", self);
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)]  && [obj respondsToSelector:@selector(collectionListWillChangeContent:)])
        {
            [obj collectionListWillChangeContent:self];
        }
    }];
}

- (void)sendDidChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"%@ Did Change", self);
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)]  && [obj respondsToSelector:@selector(collectionListDidChangeContent:)])
        {
            [obj collectionListDidChangeContent:self];
        }
    }];
}


- (void)sortPendingNotifications
{
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
        [self.pendingObjectRemoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"indexPath" ascending:NO] ]];
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
        [self.pendingObjectInsertNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath" ascending:YES] ]];
    }
    
    // Move Objects, ascending by destination index path
    if (self.pendingObjectMoveNotifications.count)
    {
        [self.pendingObjectMoveNotifications sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"nuIndexPath" ascending:YES] ]];
    }
}

- (void)sendAllPendingChangeNotifications
{
    // ---- Sort
    [self sortPendingNotifications];
    
    // ---- Send out notifications
    
    // Remove Objects, sorted descending by index path
    if (self.pendingObjectRemoveNotifications.count)
    {
        [self sendObjectNotifications:self.pendingObjectRemoveNotifications];
    }
    
    // Remove Sections, sorted descending by index
    if (self.pendingSectionRemoveNotifications.count)
    {
        [self sendSectionNotifications:self.pendingSectionRemoveNotifications];
    }
    
    // Insert Sections, ascending by index
    if (self.pendingSectionInsertNotifications.count)
    {
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
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)] && [obj respondsToSelector:@selector(collectionList:didChangeSection:atIndex:forChangeType:)])
            {
#if kRZCollectionListNotificationsLogging
                NSLog(@"%@ Changed Section %@", self, notification);
#endif
                [obj collectionList:self didChangeSection:(id<RZCollectionListSectionInfo>)notification.sectionInfo atIndex:notification.sectionIndex forChangeType:notification.type];
            }
        }];
    }];
}

- (void)sendObjectNotifications:(NSArray *)objectNotifications
{
    [objectNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)]  && [obj respondsToSelector:@selector(collectionList:didChangeObject:atIndexPath:forChangeType:newIndexPath:)])
            {
#if kRZCollectionListNotificationsLogging
                NSLog(@"%@ Changed Object %@", self, notification);
#endif
                [obj collectionList:self didChangeObject:notification.object atIndexPath:notification.indexPath forChangeType:notification.type newIndexPath:notification.nuIndexPath];
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

- (NSException*)missingProtocolMethodExceptionWithSelector:(SEL)selector
{
    return [NSException exceptionWithName:RZCollectionListMissingProtocolMethodException
                                   reason:[NSString stringWithFormat:@"RZBaseCollectionList subclass does not implement required method %@", NSStringFromSelector(selector)]
                                 userInfo:nil];
}

#pragma mark - RZCollectionList Protocol

- (NSArray*)listObservers
{
    return [self.collectionListObservers allObjects];
}

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

// ---- Subclasses must implement the below methods. Otherwise an exception will be thrown. ----

- (NSArray*)listObjects
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSArray*)sections
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSArray*)cachedSections
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSArray*)sectionIndexTitles
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (id)objectAtIndexPath:(NSIndexPath*)indexPath
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    @throw [self missingProtocolMethodExceptionWithSelector:_cmd];
}

@end