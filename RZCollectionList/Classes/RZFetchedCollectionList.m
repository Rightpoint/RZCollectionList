//
//  RZFetchedCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZFetchedCollectionList.h"
#import "RZObserverCollection.h"
#import "RZBaseSourceCollectionList_Private.h"

@interface RZFetchedCollectionList () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

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
      
        [self enqueueObjectNotificationWithObject:anObject indexPath:indexPath newIndexPath:newIndexPath type:(RZCollectionListChangeType)type];

    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (self.controller == controller)
    {
        
#if kRZCollectionListNotificationsLogging
        NSLog(@"RZFetchedCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
#endif
        
        [self enqueueSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:sectionIndex type:(RZCollectionListChangeType)type];
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
        [self sendPendingNotificationsToObservers:[self.collectionListObservers allObjects]];

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
