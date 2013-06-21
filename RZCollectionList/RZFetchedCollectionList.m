//
//  RZFetchedCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZFetchedCollectionList.h"
#import "RZObserverCollection.h"

// Box containers for storing fetched results controller notifications until didChange is called.
// This is to obey the internal ordering protocol for batch update notifications in RZCollectionList
// See wiki for details: https://github.com/Raizlabs/RZCollectionList/wiki/Batch-Notification-Order

@interface RZFetchedCollectionListSectionNotification : NSObject

@property (nonatomic, strong) id<RZCollectionListSectionInfo> sectionInfo;
@property (nonatomic, assign) NSUInteger sectionIndex;
@property (nonatomic, assign) RZCollectionListChangeType type;

- (id)initWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo index:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type;

@end

// --------------------------------------

@interface RZFetchedCollectionListObjectNotification : NSObject

@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSIndexPath *nuIndexPath; // dumb spelling, but avoids cocoa naming convention build error (can't start with "new")
@property (nonatomic, assign) RZCollectionListChangeType type;

- (id)initWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type;

@end

// --------------------------------------

@interface RZFetchedCollectionList () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

- (void)sendObjectAndSectionNotificationsToObservers;
- (void)sendSectionNotifications:(NSSet*)sectionNotifications;
- (void)sendObjectNotifications:(NSSet*)objectNotifications;

@end


@implementation RZFetchedCollectionList
@synthesize delegate = _delegate;

- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)name
{
    return [self initWithFetchedResultsController:[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:sectionNameKeyPath cacheName:name]];
}

- (id)initWithFetchedResultsController:(NSFetchedResultsController*)controller
{
    if ((self = [super init]))
    {
        self.controller = controller;
    }
    
    return self;
}

- (void)setController:(NSFetchedResultsController *)controller
{
    if (controller == _controller)
    {
        return;
    }
    
    _controller.delegate = nil;
    _controller = controller;
    controller.delegate = self;
    
    NSError *error = nil;
    if (![controller performFetch:&error])
    {
        NSLog(@"Error performing fetch for RZFetchedCollectionList controller: %@. Error: %@", controller, [error localizedDescription]);
    }
}

- (RZObserverCollection*)collectionListObservers
{
    if (nil == _collectionListObservers)
    {
        _collectionListObservers = [[RZObserverCollection alloc] init];
    }
    
    return _collectionListObservers;
}

- (void)sendObjectAndSectionNotificationsToObservers
{
    // Insert Sections
    [self sendSectionNotifications:self.sectionsInsertedDuringUpdate];
    
    // Insert Objects
    [self sendObjectNotifications:self.objectsInsertedDuringUpdate];
    
    // Remove Objects
    [self sendObjectNotifications:self.objectsRemovedDuringUpdate];
    
    // Remove Sections
    [self sendSectionNotifications:self.sectionsRemovedDuringUpdate];
    
    // Move Objects
    [self sendObjectNotifications:self.objectsMovedDuringUpdate];
    
    // Update Objects
    [self sendObjectNotifications:self.objectsUpdatedDuringUpdate];
}

- (void)sendSectionNotifications:(NSSet *)sectionNotifications
{
    [sectionNotifications enumerateObjectsUsingBlock:^(RZFetchedCollectionListSectionNotification *notification, BOOL *stop) {
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                [obj collectionList:self didChangeSection:(id<RZCollectionListSectionInfo>)notification.sectionInfo atIndex:notification.sectionIndex forChangeType:notification.type];
            }
        }];
    }];
}

- (void)sendObjectNotifications:(NSSet *)objectNotifications
{
    [objectNotifications enumerateObjectsUsingBlock:^(RZFetchedCollectionListObjectNotification *notification, BOOL *stop) {
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                [obj collectionList:self didChangeObject:notification.object atIndexPath:notification.indexPath forChangeType:notification.type newIndexPath:notification.nuIndexPath];
            }
        }];
    }];
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    return [self.controller fetchedObjects];
}

- (NSArray*)sections
{
    return [self.controller sections];
}

- (NSArray*)listObservers
{
    return [self.collectionListObservers allObjects];
}

- (NSArray*)sectionIndexTitles
{
    return [self.controller sectionIndexTitles];
}

- (id)objectAtIndexPath:(NSIndexPath*)indexPath
{
    return [self.controller objectAtIndexPath:indexPath];
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    return [self.controller indexPathForObject:object];
}

- (NSString *)sectionIndexTitleForSectionName:(NSString*)sectionName
{
    return [self.controller sectionIndexTitleForSectionName:sectionName];
}

- (NSInteger)sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)sectionIndex
{
    return [self.controller sectionForSectionIndexTitle:title atIndex:sectionIndex];
}

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    if (self.controller == controller)
    {
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change Object: %@ IndexPath:%@ Type: %d NewIndexPath: %@", anObject, indexPath, type, newIndexPath);
#endif
      
        // TODO: Maybe keep a cache of these notification objects for reuse? Probably more efficient than allocating.
        
        // cache the changes so we can send them in the desired order
        if (NSFetchedResultsChangeInsert == type)
        {
            RZFetchedCollectionListObjectNotification *insertNotification = [[RZFetchedCollectionListObjectNotification alloc] initWithObject:anObject indexPath:nil newIndexPath:newIndexPath type:RZCollectionListChangeInsert];
            [self.objectsInsertedDuringUpdate  addObject:insertNotification];
        }
        else if (NSFetchedResultsChangeDelete == type)
        {
            RZFetchedCollectionListObjectNotification *removeNotification = [[RZFetchedCollectionListObjectNotification alloc] initWithObject:anObject indexPath:indexPath newIndexPath:nil type:RZCollectionListChangeDelete];
            [self.objectsRemovedDuringUpdate  addObject:removeNotification];
        }
        else if (NSFetchedResultsChangeMove == type)
        {
            RZFetchedCollectionListObjectNotification *moveNotification = [[RZFetchedCollectionListObjectNotification alloc] initWithObject:anObject indexPath:indexPath newIndexPath:newIndexPath type:RZCollectionListChangeMove];
            [self.objectsMovedDuringUpdate  addObject:moveNotification];
        }
        else if (NSFetchedResultsChangeUpdate == type)
        {
            RZFetchedCollectionListObjectNotification *updateNotification = [[RZFetchedCollectionListObjectNotification alloc] initWithObject:anObject indexPath:indexPath newIndexPath:nil type:RZCollectionListChangeUpdate];
            [self.objectsUpdatedDuringUpdate  addObject:updateNotification];
        }

    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (self.controller == controller)
    {
        
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
#endif
        
        if (NSFetchedResultsChangeInsert == type)
        {
            RZFetchedCollectionListSectionNotification *insertNotification = [[RZFetchedCollectionListSectionNotification alloc] initWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo index:sectionIndex type:RZCollectionListChangeInsert];
            [self.sectionsInsertedDuringUpdate addObject:insertNotification];
        }
        else if (NSFetchedResultsChangeDelete)
        {
            RZFetchedCollectionListSectionNotification *removeNotification = [[RZFetchedCollectionListSectionNotification alloc] initWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo index:sectionIndex type:RZCollectionListChangeDelete];
            [self.sectionsRemovedDuringUpdate addObject:removeNotification];
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (self.controller == controller)
    {
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Will Change");
#endif
        
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                [obj collectionListWillChangeContent:self];
            }
        }];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.controller == controller)
    {
        // Send out all object/section notifications
        [self sendObjectAndSectionNotificationsToObservers];
        [self clearCachedCollectionInfo];
        
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change");
#endif
        // Send out DidChange Notifications
        [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
            {
                [obj collectionListDidChangeContent:self];
            }
        }];
    }
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    if (self.controller == controller && self.delegate && [self.delegate respondsToSelector:@selector(collectionList:sectionIndexTitleForSectionName:)])
    {
        return [self.delegate collectionList:self sectionIndexTitleForSectionName:sectionName];
    }
    
    return nil;
}

@end

@implementation RZFetchedCollectionListSectionNotification

- (id)initWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo index:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type
{
    if ((self = [super init]))
    {
        self.sectionInfo = sectionInfo;
        self.sectionIndex = sectionIndex;
        self.type = type;
    }
    
    return self;
}

@end

@implementation RZFetchedCollectionListObjectNotification

- (id)initWithObject:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath type:(RZCollectionListChangeType)type
{
    if ((self = [super init]))
    {
        self.object = object;
        self.indexPath = indexPath;
        self.nuIndexPath = newIndexPath;
        self.type = type;
    }
    return self;
}

@end
