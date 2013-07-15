//
//  RZSortedCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZSortedCollectionList.h"
#import "RZBaseCollectionList_Protected.h"

@interface RZSortedCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *indexTitle;
@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;
@property (nonatomic, assign) NSUInteger indexOffset;

@property (nonatomic, weak) RZSortedCollectionList *sortedList;

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle numberOfObjects:(NSUInteger)numberOfObjects;

@end

typedef enum {
    RZSortedSourceListContentChangeStateNoChanges,
    RZSortedSourceListContentChangeStatePotentialChanges,
    RZSortedSourceListContentChangeStateChanged
} RZSortedSourceListContentChangeState;

@interface RZSortedCollectionList ()

@property (nonatomic, strong, readwrite) id<RZCollectionList> sourceList;

@property (nonatomic, strong) NSMutableArray *sortedListObjects;
@property (nonatomic, strong) NSArray *cachedSortedListObjects;

@property (nonatomic, assign) RZSortedSourceListContentChangeState contentChangeState;

- (NSArray*)sortedSections;

// Mutation helpers
- (void)addSourceObject:(id)object;
- (void)removeSourceObject:(id)object;
- (void)updateSourceObject:(id)object;

- (void)beginPotentialUpdates;
- (void)confirmPotentialUpdates;
- (void)endPotentialUpdates;

- (void)processReceivedChangeNotifications;

@end

@implementation RZSortedCollectionList

- (id)initWithSourceList:(id<RZCollectionList>)sourceList sortDescriptors:(NSArray *)sortDescriptors
{
    if ((self = [super init]))
    {
        self.contentChangeState = RZSortedSourceListContentChangeStateNoChanges;
        
        self.sourceList = sourceList;
        self.sortDescriptors = sortDescriptors;
        
        [self.sourceList addCollectionListObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
    [self.sourceList removeCollectionListObserver:self];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
    if (sortDescriptors != _sortDescriptors)
    {
        [self sendWillChangeContentNotifications];
        
        NSArray *oldSortedObjects = self.sortedListObjects;
        NSArray *sortedObjects = [self.sourceList.listObjects sortedArrayUsingDescriptors:sortDescriptors];
        
        [oldSortedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSUInteger toIndex = [sortedObjects indexOfObject:obj];
            
            if (toIndex != idx)
            {
                NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:toIndex inSection:0];
                [self cacheObjectNotificationWithObject:obj indexPath:fromIndexPath newIndexPath:toIndexPath type:RZCollectionListChangeMove];
            }
        }];
        
        _sortDescriptors = [sortDescriptors copy];
        
        self.sortedListObjects = [sortedObjects mutableCopy];
        
        [self sendAllPendingChangeNotifications];
        [self sendDidChangeContentNotifications];
        [self resetPendingNotifications];
    }
}

- (NSArray*)sortedSections
{
    RZSortedCollectionListSectionInfo *zeroSection = [[RZSortedCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:self.listObjects.count];
    zeroSection.sortedList = self;

    return @[zeroSection];
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    return [NSArray arrayWithArray:self.sortedListObjects];
}

- (NSArray*)sections
{
    return [self sortedSections];
}

- (NSArray*)sectionIndexTitles
{
    NSArray *sections = self.sections;
    NSMutableArray *indexTitles = [NSMutableArray arrayWithCapacity:sections.count];
    
    [sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *indexTitle = ((id<RZCollectionListSectionInfo>)obj).indexTitle;
        
        if (indexTitle)
        {
            [indexTitles addObject:indexTitle];
        }
    }];
    
    return indexTitles;
}

- (id)objectAtIndexPath:(NSIndexPath*)indexPath
{
    return [self.sortedListObjects objectAtIndex:indexPath.row];
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    NSUInteger indexOfObject = [self.sortedListObjects indexOfObject:object];
    return [NSIndexPath indexPathForRow:indexOfObject inSection:0];
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    NSString *sectionIndexTitle = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(collectionList:sectionIndexTitleForSectionName:)])
    {
        sectionIndexTitle = [self.delegate collectionList:self sectionIndexTitleForSectionName:sectionName];
    }
    else
    {
        NSArray *filteredArray = [self.sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", sectionName]];
        RZSortedCollectionListSectionInfo *section = [filteredArray lastObject];
        
        sectionIndexTitle = section.indexTitle;
    }
    
    return sectionIndexTitle;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    NSArray *sections = self.sections;
    if (sectionIndex < [sections count])
    {
        id<RZCollectionListSectionInfo> section = [sections objectAtIndex:sectionIndex];
        
        if ([title isEqualToString:section.indexTitle])
        {
            return sectionIndex;
        }
    }
    
    //else binSearchForIt
    
    NSInteger index = [sections indexOfObject:title inSortedRange:NSMakeRange(0, sections.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 isKindOfClass:[NSString class]])
        {
            return [((NSString*)obj1) compare:((id<RZCollectionListSectionInfo>)obj2).indexTitle];
        }
        else
        {
            return [((id<RZCollectionListSectionInfo>)obj1).indexTitle compare:((NSString*)obj2)];
        }
    }];
    
    return index;
}

#pragma mark - Mutation Helpers

- (void)addSourceObject:(id)object
{
    [self confirmPotentialUpdates];
    
    NSUInteger insertIndex = [self.sortedListObjects indexOfObject:object inSortedRange:NSMakeRange(0, self.sortedListObjects.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        __block NSComparisonResult compResult = NSOrderedSame;
        
        [self.sortDescriptors enumerateObjectsUsingBlock:^(NSSortDescriptor *sortDesc, NSUInteger idx, BOOL *stop) {
            compResult = [sortDesc compareObject:obj1 toObject:obj2];
            
            if (compResult != NSOrderedSame)
            {
                *stop = YES;
            }
        }];
        
        return compResult;
    }];
    
    [self.sortedListObjects insertObject:object atIndex:insertIndex];
    
    NSIndexPath *addIndexPath = [NSIndexPath indexPathForRow:insertIndex inSection:0];
    [self cacheObjectNotificationWithObject:object indexPath:nil newIndexPath:addIndexPath type:RZCollectionListChangeInsert];
}

- (void)removeSourceObject:(id)object
{
    [self confirmPotentialUpdates];
    
    // message with original index
    NSUInteger objectIndex = [self.cachedSortedListObjects indexOfObject:object];
    
    NSIndexPath *sortedIndexPath = [NSIndexPath indexPathForRow:objectIndex inSection:0];
    
    // remove from current object set
    [self.sortedListObjects removeObject:object];
    
    [self cacheObjectNotificationWithObject:object indexPath:sortedIndexPath newIndexPath:nil type:RZCollectionListChangeDelete];
}

- (void)updateSourceObject:(id)object
{
    [self confirmPotentialUpdates];
    
    // former index path
    NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:[self.cachedSortedListObjects indexOfObject:object] inSection:0];
    
    NSMutableArray *sortedListCopy = [self.sortedListObjects mutableCopy];
    
    NSUInteger currentIndex = [sortedListCopy indexOfObject:object];
    
    [sortedListCopy removeObjectAtIndex:currentIndex];
    
    NSUInteger insertIndex = [sortedListCopy indexOfObject:object inSortedRange:NSMakeRange(0, sortedListCopy.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        __block NSComparisonResult compResult = NSOrderedSame;
        
        [self.sortDescriptors enumerateObjectsUsingBlock:^(NSSortDescriptor *sortDesc, NSUInteger idx, BOOL *stop) {
            compResult = [sortDesc compareObject:obj1 toObject:obj2];
            
            if (compResult != NSOrderedSame)
            {
                *stop = YES;
            }
        }];
        
        return compResult;
    }];
    
    [sortedListCopy insertObject:object atIndex:insertIndex];
    
    if (currentIndex != insertIndex)
    {
        self.sortedListObjects = sortedListCopy;
        
        NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:insertIndex inSection:0];
        
        // explicitly move and update
        [self cacheObjectNotificationWithObject:object indexPath:prevIndexPath newIndexPath:toIndexPath type:RZCollectionListChangeMove];
        [self cacheObjectNotificationWithObject:object indexPath:prevIndexPath newIndexPath:toIndexPath type:RZCollectionListChangeUpdate];
    }
    else
    {
        // just update
        [self cacheObjectNotificationWithObject:object indexPath:prevIndexPath newIndexPath:[self indexPathForObject:object] type:RZCollectionListChangeUpdate];
    }

}

- (void)beginPotentialUpdates
{
    self.contentChangeState = RZSortedSourceListContentChangeStatePotentialChanges;
    self.cachedSortedListObjects = [self.sortedListObjects copy];
}

- (void)confirmPotentialUpdates
{
    if (self.contentChangeState == RZSortedSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }
    
    self.contentChangeState = RZSortedSourceListContentChangeStateChanged;
}

- (void)endPotentialUpdates
{
    [self processReceivedChangeNotifications];
    
    if (self.contentChangeState == RZSortedSourceListContentChangeStateChanged)
    {
        [self sendAllPendingChangeNotifications];
        [self sendDidChangeContentNotifications];
    }
    
    [self resetPendingNotifications];
    self.contentChangeState = RZSortedSourceListContentChangeStateNoChanges;
    self.cachedSortedListObjects = nil;
}

- (void)processReceivedChangeNotifications
{
    // -- Make local copies of received notification caches --
    
    // -- Object
    NSArray *objectRemoveNotifications   = [self.pendingObjectRemoveNotifications copy];
    NSArray *objectInsertNotifications   = [self.pendingObjectInsertNotifications copy];    
    NSArray *objectUpdateNotifications   = [self.pendingObjectUpdateNotifications copy];
    
    // -- clear cache in prep for outgoing notifications --
    
    [self resetPendingNotifications];
    
    // -- process incoming notifications - mutate internal state and produce cached outgoing notifications --
    
    [objectRemoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self removeSourceObject:notification.object];
    }];
    
    [objectInsertNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self addSourceObject:notification.object];
    }];
    
    [objectUpdateNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self updateSourceObject:notification.object];
    }];
    
    // -- Update all new index paths for any operations which may have changed them --
    
    [self.allPendingObjectNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        
        if (notification.nuIndexPath)
        {
            notification.nuIndexPath = [self indexPathForObject:notification.object];
        }
        
    }];
    
    // get rid of any invalid move operations (same start/end path)
    NSMutableIndexSet *invalidMoves = [NSMutableIndexSet indexSet];
    [self.pendingObjectMoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        if (nil == notification.nuIndexPath || nil == notification.indexPath || [notification.nuIndexPath isEqual:notification.indexPath])
        {
            [invalidMoves addIndex:idx];
        }
    }];
    
    [self.pendingObjectMoveNotifications removeObjectsAtIndexes:invalidMoves];
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    switch(type) {
        case RZCollectionListChangeInsert:
        case RZCollectionListChangeDelete:
        case RZCollectionListChangeUpdate:
            [self cacheObjectNotificationWithObject:object indexPath:indexPath newIndexPath:newIndexPath type:type];
            break;
        case RZCollectionListChangeMove:
            // we don't care about move
            break;
        default:
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    // No action taken on purpose. Sorted list flattens all sections.
    switch(type) {
        case RZCollectionListChangeInsert:
        case RZCollectionListChangeDelete:
            break;
        default:
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    [self beginPotentialUpdates];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    [self endPotentialUpdates];
}


@end

@implementation RZSortedCollectionListSectionInfo

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle numberOfObjects:(NSUInteger)numberOfObjects
{
    if ((self = [super init]))
    {
        self.name = name;
        self.indexTitle = indexTitle;
        self.numberOfObjects = numberOfObjects;
    }
    
    return self;
}

- (NSString*)indexTitle
{
    if (nil == _indexTitle && self.name && self.name.length > 0)
    {
        _indexTitle = [[self.name substringToIndex:1] uppercaseString];
    }
    
    return _indexTitle;
}

- (NSArray*)objects
{
    return [self.sortedList.listObjects subarrayWithRange:NSMakeRange(self.indexOffset, self.numberOfObjects)];
}

- (NSRange)range
{
    return NSMakeRange(self.indexOffset, self.numberOfObjects);
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ Name:%@ IndexTitle:%@ IndexOffset:%u NumberOfObjects:%u", [super description], self.name, self.indexTitle, self.indexOffset, self.numberOfObjects];
}

- (id)copyWithZone:(NSZone *)zone
{
    RZSortedCollectionListSectionInfo *copy = [[RZSortedCollectionListSectionInfo alloc] initWithName:self.name sectionIndexTitle:self.indexTitle numberOfObjects:self.numberOfObjects];
    copy.indexOffset = self.indexOffset;
    copy.sortedList = self.sortedList;
    return copy;
}

@end
