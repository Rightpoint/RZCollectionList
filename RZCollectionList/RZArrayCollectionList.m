//
//  RZArrayCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZArrayCollectionList.h"
#import "RZObserverCollection.h"

@interface RZArrayCollectionListSectionInfo ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *indexTitle;
@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;

@property (nonatomic, weak) RZArrayCollectionList *arrayList;

- (NSRange)range;

@end

@interface RZArrayCollectionList ()
{
@private
    struct _arrayCollectionListFlags {
        unsigned int _sendSectionIndexTitleForSectionName:1;
    } _flags;
}

@property (nonatomic, strong) NSMutableArray *sectionsInfo;
@property (nonatomic, strong) NSMutableArray *objects;

// batch update
@property (nonatomic, strong) NSArray *sectionsInfoBeforeBatchUpdateDeep;       // deep-copies - range/offset will not change during update
@property (nonatomic, strong) NSArray *sectionsInfoBeforeBatchUpdateShallow;    // shallow-copies - use only for index lookup after update
@property (nonatomic, strong) NSArray *objectsBeforeBatchUpdate;

@property (nonatomic, strong) NSMutableSet *sectionsInsertedDuringBatchUpdate;
@property (nonatomic, strong) NSMutableSet *sectionsRemovedDuringBatchUpdate;
@property (nonatomic, strong) NSMutableSet *objectsInsertedDuringBatchUpdate;
@property (nonatomic, strong) NSMutableSet *objectsRemovedDuringBatchUpdate;
@property (nonatomic, strong) NSMutableSet *objectsMovedDuringBatchUpdate;
@property (nonatomic, strong) NSMutableSet *objectsUpdatedDuringBatchUpdate;

@property (nonatomic, assign, getter = isBatchUpdating) BOOL batchUpdating;

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

+ (NSArray*)sectionsForObjects:(NSArray*)objects withNameKeyPath:(NSString*)keyPath;

- (RZArrayCollectionListSectionInfo*)sectionInfoForSection:(NSUInteger)section;
- (void)updateSection:(RZArrayCollectionListSectionInfo*)section withObjectCountChange:(NSInteger)countChange;

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications;
- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications;
- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object sendNotifications:(BOOL)shouldSendNotifications;
- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath sendNotifications:(BOOL)shouldSendNotifications;

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications;
- (void)removeSectionAtIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications;

- (NSIndexPath*)preUpdateIndexPathForObject:(id)object;

- (void)sendWillChangeContentNotifications;
- (void)sendDidChangeContentNotifications;
- (void)sendDidChangeObjectNotification:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;
- (void)sendDidChangeSectionNotification:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex  forChangeType:(RZCollectionListChangeType)type;

- (void)sendBatchChangeNotifications;

- (void)objectUpdateNotificationReceived:(NSNotification*)notification;

@end

@implementation RZArrayCollectionList
@synthesize delegate = _delegate;

- (id)initWithArray:(NSArray *)array sectionNameKeyPath:(NSString *)keyPath
{
    NSArray *sections = [RZArrayCollectionList sectionsForObjects:array withNameKeyPath:keyPath];
    return [self initWithArray:array sections:sections];
}

- (id)initWithArray:(NSArray *)array sections:(NSArray *)sections
{
    if ((self = [super init]))
    {
        if (array) {
            self.objects = [array mutableCopy];
        } else {
            self.objects = [[NSArray array] mutableCopy];
        }
        
        if (sections){
            self.sectionsInfo = [sections mutableCopy];
        } else {
            self.sectionsInfo = [[NSArray array] mutableCopy];
        }
        
        self.sectionsInsertedDuringBatchUpdate  = [NSMutableSet setWithCapacity:8];
        self.sectionsRemovedDuringBatchUpdate   = [NSMutableSet setWithCapacity:8];
        self.objectsInsertedDuringBatchUpdate   = [NSMutableSet setWithCapacity:16];
        self.objectsRemovedDuringBatchUpdate    = [NSMutableSet setWithCapacity:16];
        self.objectsMovedDuringBatchUpdate      = [NSMutableSet setWithCapacity:16];
        self.objectsRemovedDuringBatchUpdate    = [NSMutableSet setWithCapacity:16];
        
        [self.sectionsInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ((RZArrayCollectionListSectionInfo*)obj).arrayList = self;
        }];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDelegate:(id<RZCollectionListDelegate>)delegate
{
    if (delegate == _delegate)
    {
        return;
    }
    
    _delegate = delegate;
    
    _flags._sendSectionIndexTitleForSectionName = [delegate respondsToSelector:@selector(collectionList:sectionIndexTitleForSectionName:)];
}

- (RZObserverCollection*)collectionListObservers
{
    if (nil == _collectionListObservers)
    {
        _collectionListObservers = [[RZObserverCollection alloc] init];
    }
    
    return _collectionListObservers;
}

- (void)setObjectUpdateNotifications:(NSArray *)objectUpdateNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
    
    _objectUpdateNotifications = [objectUpdateNotifications copy];
    
    if (nil != _objectUpdateNotifications && _objectUpdateNotifications.count > 0)
    {
        [self.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [_objectUpdateNotifications enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
                [notificationCenter addObserver:self selector:@selector(objectUpdateNotificationReceived:) name:name object:obj];
            }];
        }];
    }
}

#pragma mark - Mutators

- (void)addObject:(id)object toSection:(NSUInteger)section
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self sectionInfoForSection:section];
    [self insertObject:object atIndexPath:[NSIndexPath indexPathForRow:sectionInfo.numberOfObjects inSection:section]];
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self insertObject:object atIndexPath:indexPath sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)removeObject:(id)object
{
    NSIndexPath *indexPath = [self indexPathForObject:object];
    
    if (indexPath)
    {
        [self removeObjectAtIndexPath:indexPath];
    }
}

- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self removeObjectAtIndexPath:indexPath sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self replaceObjectAtIndexPath:indexPath withObject:object sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self moveObjectAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)removeAllObjects
{
    // avoid mutation during enumeration
    NSArray *objects = [[self objects] copy];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self removeObject:obj];
    }];
}

- (void)addSection:(RZArrayCollectionListSectionInfo*)section
{
    [self insertSection:section atIndex:self.sectionsInfo.count];
}

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self insertSection:section atIndex:index sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)removeSection:(RZArrayCollectionListSectionInfo*)section
{
    NSUInteger index = [self.sectionsInfo indexOfObject:section];
    
    [self removeSectionAtIndex:index];
}

- (void)removeSectionAtIndex:(NSUInteger)index
{
    if (!self.batchUpdating)
    {
        [self sendWillChangeContentNotifications];
    }
    
    [self removeSectionAtIndex:index sendNotifications:!self.batchUpdating];
    
    if (!self.batchUpdating)
    {
        [self sendDidChangeContentNotifications];
    }
}

- (void)beginUpdates
{
    if(!self.batchUpdating)
    {
        self.batchUpdating = YES;
        self.objectsBeforeBatchUpdate = [self.objects copy];
       
        // shallow copy sections
        self.sectionsInfoBeforeBatchUpdateShallow = [self.sectionsInfo copy];
        
        // deep copy sections
        NSMutableArray *sectionCopies = [NSMutableArray arrayWithCapacity:self.sectionsInfo.count];
        [self.sectionsInfo enumerateObjectsUsingBlock:^(RZArrayCollectionListSectionInfo *sectionInfo, NSUInteger idx, BOOL *stop) {
            [sectionCopies addObject:[sectionInfo copy]];
        }];
        self.sectionsInfoBeforeBatchUpdateDeep = sectionCopies;
        
        [self sendWillChangeContentNotifications];
    }
}

- (void)endUpdates
{
    if (self.batchUpdating)
    {
        [self sendBatchChangeNotifications];
        [self sendDidChangeContentNotifications];
        self.batchUpdating = NO;
        
        self.objectsBeforeBatchUpdate = nil;
        self.sectionsInfoBeforeBatchUpdateDeep = nil;
        self.sectionsInfoBeforeBatchUpdateShallow = nil;
        
        // cleanup on aisle 7
        [self.sectionsInsertedDuringBatchUpdate removeAllObjects];
        [self.sectionsRemovedDuringBatchUpdate removeAllObjects];
        [self.objectsInsertedDuringBatchUpdate removeAllObjects];
        [self.objectsRemovedDuringBatchUpdate removeAllObjects];
        [self.objectsMovedDuringBatchUpdate removeAllObjects];
        [self.objectsUpdatedDuringBatchUpdate removeAllObjects];
    }
}

#pragma mark - Internal Mutators

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self sectionInfoForSection:indexPath.section];
    NSUInteger index = sectionInfo.indexOffset + indexPath.row;
    
    if (nil != object && nil != indexPath && index <= self.objects.count)
    {
        // handle the "move" method calling insert - don't add to set in that case
        if (self.isBatchUpdating)
        {
            [self.objectsInsertedDuringBatchUpdate addObject:object];
        }
        
        [self.objects insertObject:object atIndex:index];
        
        if (nil != self.objectUpdateNotifications)
        {
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            
            [self.objectUpdateNotifications enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
                [notificationCenter addObserver:self selector:@selector(objectUpdateNotificationReceived:) name:name object:object];
            }];
        }
        
        [self updateSection:sectionInfo withObjectCountChange:1];
        
        if (shouldSendNotifications)
        {
            [self sendDidChangeObjectNotification:object atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:indexPath];
        }
    }
}

- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self sectionInfoForSection:indexPath.section];
    NSUInteger index = sectionInfo.indexOffset + indexPath.row;
    
    id object = nil;
    
    if (index < self.objects.count)
    {
        object = [self.objects objectAtIndex:index];
    }
    
    if (object)
    {
        if (self.isBatchUpdating)
        {
            [self.objectsRemovedDuringBatchUpdate addObject:object];
        }
        
        if (nil != self.objectUpdateNotifications)
        {
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            
            [self.objectUpdateNotifications enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
                [notificationCenter removeObserver:self name:name object:object];
            }];
        }
        
        [self.objects removeObjectAtIndex:index];
        
        [self updateSection:sectionInfo withObjectCountChange:-1];
        
        if (shouldSendNotifications)
        {
            [self sendDidChangeObjectNotification:object atIndexPath:indexPath forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
        }

    }
}

- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object sendNotifications:(BOOL)shouldSendNotifications
{
    if (nil != indexPath && nil != object)
    {
        RZArrayCollectionListSectionInfo *sectionInfo = [self sectionInfoForSection:indexPath.section];
        NSUInteger index = sectionInfo.indexOffset + indexPath.row;
        
        if (index < self.objects.count)
        {
            if (self.isBatchUpdating)
            {
                [self.objectsUpdatedDuringBatchUpdate addObject:object];
            }
            
            id oldObject = [self.objects objectAtIndex:index];
            
            if (nil != self.objectUpdateNotifications && oldObject != object)
            {
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                
                [self.objectUpdateNotifications enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
                    [notificationCenter removeObserver:self name:name object:oldObject];
                    [notificationCenter addObserver:self selector:@selector(objectUpdateNotificationReceived:) name:name object:object];
                }];
            }
            
            [self.objects replaceObjectAtIndex:index withObject:object];
            
            if (shouldSendNotifications)
            {
                [self sendDidChangeObjectNotification:object atIndexPath:indexPath forChangeType:RZCollectionListChangeUpdate newIndexPath:nil];
            }
        }
    }
}

- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath sendNotifications:(BOOL)shouldSendNotifications
{
    if (nil != sourceIndexPath && nil != destinationIndexPath)
    {
        NSIndexPath *destIndexPath = destinationIndexPath;
        NSIndexPath *removeIndexPath = sourceIndexPath;
        
        if (sourceIndexPath.section == destinationIndexPath.section)
        {
            if (destinationIndexPath.row < sourceIndexPath.row)
            {
                removeIndexPath = [NSIndexPath indexPathForRow:(removeIndexPath.row + 1) inSection:removeIndexPath.section];
            }
            else
            {
                destIndexPath = [NSIndexPath indexPathForRow:(destIndexPath.row + 1) inSection:destIndexPath.section];
            }
        }
        
        id object = [self objectAtIndexPath:sourceIndexPath];
        
        if (nil != object)
        {
            
            if (self.isBatchUpdating){
                // Don't send an extra notification for a newly inserted object in a batch operation
                if (![self.objectsInsertedDuringBatchUpdate containsObject:object])
                {
                    [self.objectsMovedDuringBatchUpdate addObject:object];
                }
            }
            
            // ND: I manually unwound the insert/remove calls so the batch logic doesn't get messed up.
            
            // INSERT AT NEW INDEX
            
            RZArrayCollectionListSectionInfo *insertSectionInfo = [self sectionInfoForSection:destIndexPath.section];
            NSUInteger insertIndex = insertSectionInfo.indexOffset + destIndexPath.row;
            
            if (nil != object && nil != destIndexPath && insertIndex <= self.objects.count)
            {
                [self.objects insertObject:object atIndex:insertIndex];
                [self updateSection:insertSectionInfo withObjectCountChange:1];
            }
            
            // REMOVE FROM OLD INDEX
    
            RZArrayCollectionListSectionInfo *removeSectionInfo = [self sectionInfoForSection:removeIndexPath.section];
            NSUInteger removeIndex = removeSectionInfo.indexOffset + removeIndexPath.row;
            [self.objects removeObjectAtIndex:removeIndex];
            [self updateSection:removeSectionInfo withObjectCountChange:-1];
            

            // SEND MOVE NOTIFICATION
            
            if (shouldSendNotifications)
            {
                [self sendDidChangeObjectNotification:object atIndexPath:sourceIndexPath forChangeType:RZCollectionListChangeMove newIndexPath:destinationIndexPath];
            }
        }
    }
}

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications
{
    if (nil != section && index <= self.sectionsInfo.count)
    {
        if (self.isBatchUpdating)
        {
            [self.sectionsInsertedDuringBatchUpdate addObject:section];
        }
        
        if (index > 0){
            RZArrayCollectionListSectionInfo *prevSection = [self.sectionsInfo objectAtIndex:index-1];
            section.indexOffset = prevSection.indexOffset + prevSection.numberOfObjects;
        }
        
        [self.sectionsInfo insertObject:section atIndex:index];
        section.arrayList = self;
        
        if (shouldSendNotifications)
        {
            [self sendDidChangeSectionNotification:section atIndex:index forChangeType:RZCollectionListChangeInsert];
        }
    }
}

- (void)removeSectionAtIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self sectionInfoForSection:index];
    
    if (sectionInfo.numberOfObjects > 0)
    {
        NSArray *objectsToRemove = [self.objects subarrayWithRange:sectionInfo.range];
        
        [self.objects removeObjectsInRange:sectionInfo.range];
        
        [self updateSection:sectionInfo withObjectCountChange:-objectsToRemove.count];
        
        [objectsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if (self.isBatchUpdating)
            {
                [self.objectsRemovedDuringBatchUpdate addObject:obj];
            }
            
            if (nil != self.objectUpdateNotifications)
            {
                NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                
                [self.objectUpdateNotifications enumerateObjectsUsingBlock:^(id name, NSUInteger idx, BOOL *stop) {
                    [notificationCenter removeObserver:self name:name object:obj];
                }];
            }
            
            if (shouldSendNotifications)
            {
                [self sendDidChangeObjectNotification:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:index] forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
            }
        }];
    }
    
    if (index < self.sectionsInfo.count)
    {
        if (self.isBatchUpdating)
        {
            [self.sectionsRemovedDuringBatchUpdate addObject:sectionInfo];
        }
        
        [self.sectionsInfo removeObjectAtIndex:index];
        sectionInfo.arrayList = nil;
        
        if (shouldSendNotifications)
        {
            [self sendDidChangeSectionNotification:sectionInfo atIndex:index forChangeType:RZCollectionListChangeDelete];
        }
    }
}

#pragma mark - Batch update helpers

- (NSIndexPath*)preUpdateIndexPathForObject:(id)object
{
    NSUInteger index = [self.objectsBeforeBatchUpdate indexOfObject:object];
    
    __block NSUInteger rowIndex = 0;
    NSUInteger sectionIndex = [self.sectionsInfoBeforeBatchUpdateDeep indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        RZArrayCollectionListSectionInfo *section = (RZArrayCollectionListSectionInfo*)obj;
        BOOL inRange = NSLocationInRange(index, section.range);
        
        if (inRange)
        {
            rowIndex = index - section.indexOffset;
            *stop = YES;
        }
        
        return inRange;
    }];
    
    NSIndexPath *indexPathForObject = nil;
    
    if (sectionIndex != NSNotFound)
    {
        indexPathForObject = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    }
    
    return indexPathForObject;
}

#pragma mark - Notification Helpers

- (void)sendWillChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZArrayCollectionList Will Change");
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionListWillChangeContent:self];
        }
    }];
}

- (void)sendDidChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZArrayCollectionList Did Change");
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionListDidChangeContent:self];
        }
    }];
}

- (void)sendDidChangeObjectNotification:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZArrayCollectionList Did Change Object: %@ IndexPath:%@ Type: %d NewIndexPath: %@", object, indexPath, type, newIndexPath);
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionList:self didChangeObject:object atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
        }
    }];
}

- (void)sendDidChangeSectionNotification:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex  forChangeType:(RZCollectionListChangeType)type
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZArrayCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionList:self didChangeSection:sectionInfo atIndex:sectionIndex forChangeType:type];
        }
    }];
}

- (void)sendBatchChangeNotifications
{

    // section removals
    
    [self.sectionsRemovedDuringBatchUpdate enumerateObjectsUsingBlock:^(RZArrayCollectionListSectionInfo * sectionInfo, BOOL *stop) {
        [self sendDidChangeSectionNotification:sectionInfo atIndex:[self.sectionsInfoBeforeBatchUpdateShallow indexOfObject:sectionInfo] forChangeType:RZCollectionListChangeDelete];
    }];
    
    // object removals

    [self.objectsRemovedDuringBatchUpdate enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self sendDidChangeObjectNotification:obj atIndexPath:[self preUpdateIndexPathForObject:obj] forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
    }];
    
    // section insertions
    
    [self.sectionsInsertedDuringBatchUpdate enumerateObjectsUsingBlock:^(RZArrayCollectionListSectionInfo * sectionInfo, BOOL *stop) {
        [self sendDidChangeSectionNotification:sectionInfo atIndex:[self.sections indexOfObject:sectionInfo] forChangeType:RZCollectionListChangeInsert];
    }];
    
    // object insertions
    
    [self.objectsInsertedDuringBatchUpdate enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self sendDidChangeObjectNotification:obj atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:[self indexPathForObject:obj]];
    }];
    
    // object moves
    
    [self.objectsMovedDuringBatchUpdate enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
       
        NSIndexPath *prevIndexPath = [self preUpdateIndexPathForObject:obj];
        NSIndexPath *currIndexPath = [self indexPathForObject:obj];
        if (prevIndexPath && currIndexPath && ![prevIndexPath isEqual:currIndexPath])
        {
            [self sendDidChangeObjectNotification:obj atIndexPath:prevIndexPath forChangeType:RZCollectionListChangeMove newIndexPath:currIndexPath];
        }
        
    }];
    
    // object updates
    
    [self.objectsUpdatedDuringBatchUpdate enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if (![self.objectsRemovedDuringBatchUpdate containsObject:obj])
        {
            [self sendDidChangeObjectNotification:obj atIndexPath:[self preUpdateIndexPathForObject:obj] forChangeType:RZCollectionListChangeUpdate newIndexPath:[self indexPathForObject:obj]];
        }
    }];
}

#pragma mark - ObjectUpdateObservation

- (void)objectUpdateNotificationReceived:(NSNotification*)notification
{
    id object = notification.object;
    
    NSIndexPath *indexPath = [self indexPathForObject:object];
    
    if (nil != object && nil != indexPath)
    {
        if (!self.batchUpdating)
        {
            [self sendWillChangeContentNotifications];
            
            [self sendDidChangeObjectNotification:object atIndexPath:indexPath forChangeType:RZCollectionListChangeUpdate newIndexPath:nil];
            
            [self sendDidChangeContentNotifications];
        }
        else
        {
            [self.objectsUpdatedDuringBatchUpdate addObject:object];
        }
    }
}

#pragma mark - SectionInfo Helpers

+ (NSArray*)sectionsForObjects:(NSArray*)objects withNameKeyPath:(NSString*)keyPath
{
    NSArray *sections = nil;
    
    if (nil == keyPath)
    {
        RZArrayCollectionListSectionInfo *sectionZero = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil numberOfObjects:[objects count]];
        
        sections = @[sectionZero];
    }
    else
    {
        NSMutableArray *sectionsInfo = [NSMutableArray array];
        __block RZArrayCollectionListSectionInfo *currentSection = nil;
        
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id value = [obj valueForKeyPath:keyPath];
            
            NSString *sectionName = nil;
            
            if ([value isKindOfClass:[NSString class]])
            {
                sectionName = value;
            }
            else if ([value respondsToSelector:@selector(stringValue)])
            {
                sectionName = [value stringValue];
            }
            
            if (nil == sectionName)
            {
                @throw [NSException exceptionWithName:@"RZArrayCollectionListInvalidSecionNameKeyPath" reason:[NSString stringWithFormat:@"An object at index %u returned nil for the keyPath:%@", idx, keyPath] userInfo:@{@"keyPath" : keyPath, @"index" : [NSNumber numberWithUnsignedInteger:idx], @"object" : obj}];
            }
            
            if (![currentSection.name isEqualToString:sectionName])
            {
                if (nil != currentSection)
                {
                    currentSection.numberOfObjects = idx - currentSection.indexOffset;
                    
                    if (nil != currentSection)
                    {
                        [sectionsInfo addObject:currentSection];
                    }
                }
                
                RZArrayCollectionListSectionInfo *nextSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:sectionName sectionIndexTitle:nil numberOfObjects:0];
                nextSection.indexOffset = idx;
                
                currentSection = nextSection;
            }
            
        }];
        
        currentSection.numberOfObjects = [objects count] - currentSection.indexOffset;
        
        if (nil != currentSection)
        {
            [sectionsInfo addObject:currentSection];
        }
        
        sections = sectionsInfo;
    }
    
    return sections;
}

- (RZArrayCollectionListSectionInfo*)sectionInfoForSection:(NSUInteger)section
{
    if (self.sectionsInfo.count == 0)
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"Section %u not found. No sections exist.", section] userInfo:nil];
    }
    else if (section >= self.sectionsInfo.count)
    {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"Section %u not found. Outside valid section index range 0..%u", section, self.sectionsInfo.count-1] userInfo:nil];
    }
    
    return [self.sectionsInfo objectAtIndex:section];
}

- (void)updateSection:(RZArrayCollectionListSectionInfo*)section withObjectCountChange:(NSInteger)countChange
{
    section.numberOfObjects += countChange;
    
    [self.sectionsInfo enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (obj == section)
        {
            *stop = YES;
        }
        else
        {
            RZArrayCollectionListSectionInfo *currentSection = (RZArrayCollectionListSectionInfo*)obj;
            currentSection.indexOffset += countChange;
        }
    }];
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    return [self.objects copy];
}

- (NSArray*)sections
{
    return [self.sectionsInfo copy];
}

- (NSArray*)listObservers
{
    return [self.collectionListObservers allObjects];
}

- (NSArray*)sectionIndexTitles
{
    NSMutableArray *indexTitles = [NSMutableArray arrayWithCapacity:self.sectionsInfo.count];
    
    [self.sectionsInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *indexTitle = ((RZArrayCollectionListSectionInfo*)obj).indexTitle;
        
        if (indexTitle)
        {
            [indexTitles addObject:indexTitle];
        }
    }];
    
    return indexTitles;
}

- (id)objectAtIndexPath:(NSIndexPath*)indexPath
{
    RZArrayCollectionListSectionInfo *section = [self sectionInfoForSection:indexPath.section];
    
    NSUInteger index = section.indexOffset + indexPath.row;
    
    id object = nil;
    
    if (index < [self.objects count])
    {
        object = [self.objects objectAtIndex:index];
    }
    
    return object;
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    NSUInteger index = [self.objects indexOfObject:object];
    
    __block NSUInteger rowIndex = 0;
    NSUInteger sectionIndex = [self.sectionsInfo indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        RZArrayCollectionListSectionInfo *section = (RZArrayCollectionListSectionInfo*)obj;
        BOOL inRange = NSLocationInRange(index, section.range);
        
        if (inRange)
        {
            rowIndex = index - section.indexOffset;
            *stop = YES;
        }
        
        return inRange;
    }];
    
    NSIndexPath *indexPathForObject = nil;
    
    if (sectionIndex != NSNotFound)
    {
        indexPathForObject = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    }
    
    return indexPathForObject;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    NSString *sectionIndexTitle = nil;
    
    if (_flags._sendSectionIndexTitleForSectionName)
    {
        sectionIndexTitle = [self.delegate collectionList:self sectionIndexTitleForSectionName:sectionName];
    }
    else
    {
        NSArray *filteredArray = [self.sectionsInfo filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", sectionName]];
        RZArrayCollectionListSectionInfo *section = [filteredArray lastObject];
        
        sectionIndexTitle = section.indexTitle;
    }
    
    return sectionIndexTitle;
}

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    if (sectionIndex < [self.sectionsInfo count])
    {
        RZArrayCollectionListSectionInfo *section = [self sectionInfoForSection:sectionIndex];
        
        if ([title isEqualToString:section.indexTitle])
        {
            return sectionIndex;
        }
    }
    
    //else binSearchForIt
    
    RZArrayCollectionListSectionInfo *tempSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:title numberOfObjects:0];
    
    NSInteger index = [self.sectionsInfo indexOfObject:tempSection inSortedRange:NSMakeRange(0, self.sectionsInfo.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((RZArrayCollectionListSectionInfo*)obj1).indexTitle compare:((RZArrayCollectionListSectionInfo*)obj2).indexTitle];
    }];
    
    return index;
}

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

@end


@implementation RZArrayCollectionListSectionInfo

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
    return [self.arrayList.listObjects subarrayWithRange:NSMakeRange(self.indexOffset, self.numberOfObjects)];
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
    RZArrayCollectionListSectionInfo *copy = [[RZArrayCollectionListSectionInfo alloc] initWithName:self.name sectionIndexTitle:self.indexTitle numberOfObjects:self.numberOfObjects];
    copy.indexOffset = self.indexOffset;
    return copy;
}

@end