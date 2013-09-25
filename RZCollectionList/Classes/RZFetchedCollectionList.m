//
//  RZFetchedCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZFetchedCollectionList.h"
#import "RZObserverCollection.h"
#import "RZBaseCollectionList_Private.h"

@interface RZFetchedCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, strong, readwrite) NSArray *objects;

@property (nonatomic, strong) id<NSFetchedResultsSectionInfo> fetchedSectionInfo;
@property (nonatomic, assign) BOOL isCachedCopy;

- (id)initWithFetchedResultsSectionInfo:(id<NSFetchedResultsSectionInfo>)fetchedSectionInfo;

@end


@interface RZFetchedCollectionList () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSArray *cachedFetchedSections;

- (void)calculateCurrentIndexPathsForUpdates;

@end

@implementation RZFetchedCollectionList

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

- (void)calculateCurrentIndexPathsForUpdates
{
    [self.pendingObjectUpdateNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        notification.nuIndexPath = [self indexPathForObject:notification.object];
    }];
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    return [self.controller fetchedObjects];
}

- (NSArray*)sections
{
    // convert to internal, cacheable section representation
    NSArray *rawSections = [self.controller sections];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:rawSections.count];
    [rawSections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo> fetchedSection, NSUInteger idx, BOOL *stop) {
        [sections addObject:[[RZFetchedCollectionListSectionInfo alloc] initWithFetchedResultsSectionInfo:fetchedSection]];
    }];
    return sections;
}

- (NSArray*)cachedSections
{
    // if we aren't updating, just return normal sections
    if (nil != self.cachedFetchedSections)
    {
        return [self.cachedFetchedSections copy];
    }
    return self.sections;
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    if (self.controller == controller)
    {
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change Object: %@ IndexPath:%@ Type: %d NewIndexPath: %@\n", changeType, anObject, indexPath, type, newIndexPath);
#endif
      
        [self cacheObjectNotificationWithObject:anObject indexPath:indexPath newIndexPath:newIndexPath type:(RZCollectionListChangeType)type];

    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (self.controller == controller)
    {
        
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
#endif
        
        [self cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:sectionIndex type:(RZCollectionListChangeType)type];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if (self.controller == controller)
    {
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Will Change");
#endif
        self.cachedFetchedSections = [self.sections valueForKey:@"cachedCopy"];
        [self sendWillChangeContentNotifications];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.controller == controller)
    {
        // get current index paths for update notifications
        [self calculateCurrentIndexPathsForUpdates];
        
        // Send out all object/section notifications
        [self sendAllPendingChangeNotifications];

#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change");
#endif
        // Send out DidChange Notifications
        [self sendDidChangeContentNotifications];
        
        self.cachedFetchedSections = nil;
    }
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
{
    if (self.controller == controller && self.delegate && [self.delegate respondsToSelector:@selector(collectionList:sectionIndexTitleForSectionName:)])
    {
        return [self.delegate collectionList:self sectionIndexTitleForSectionName:sectionName];
    }
    
    return [self.controller sectionIndexTitleForSectionName:sectionName];
}

@end

@implementation RZFetchedCollectionListSectionInfo

- (id)initWithFetchedResultsSectionInfo:(id<NSFetchedResultsSectionInfo>)fetchedSectionInfo
{
    if ((self = [super init]))
    {
        self.fetchedSectionInfo = fetchedSectionInfo;
    }
    return self;
}

- (NSString*)name
{
    return [self.fetchedSectionInfo name];
}

- (NSString*)indexTitle
{
    return [self.fetchedSectionInfo indexTitle];
}

- (NSArray*)objects
{
    if (self.isCachedCopy)
    {
        return _objects;
    }
    return [self.fetchedSectionInfo objects];
}

- (NSUInteger)numberOfObjects
{
    if (self.isCachedCopy)
    {
        return [_objects count];
    }
    return [self.fetchedSectionInfo numberOfObjects];
}

- (id<RZCollectionListSectionInfo>)cachedCopy
{
    RZFetchedCollectionListSectionInfo *copy = [[RZFetchedCollectionListSectionInfo alloc] initWithFetchedResultsSectionInfo:self.fetchedSectionInfo];
    copy.objects = [self objects];
    copy.isCachedCopy = YES;
    return copy;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RZFetchedCollectionListSectionInfo class]])
    {
        return (self.fetchedSectionInfo == [object fetchedSectionInfo]) && (self.isCachedCopy == [object isCachedCopy]);
    }
    return NO;
}

- (NSUInteger)hash
{
    // Might want to try to find a better hash for this...
    return [[self.fetchedSectionInfo objects] hash] ^ self.numberOfObjects;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ number of objects: %d  isCached: %@", [super description], self.numberOfObjects, self.isCachedCopy ? @"yes" : @"no"];
}

@end
