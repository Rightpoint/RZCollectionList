//
//  RZFilteredCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/12/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZFilteredCollectionList.h"
#import "RZBaseCollectionList_Private.h"
#import "RZObserverCollection.h"

@interface RZFilteredCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, strong, readwrite) NSArray *objects;

@property (nonatomic, weak) id<RZCollectionListSectionInfo> sourceSectionInfo;
@property (nonatomic, weak) RZFilteredCollectionList *filteredList;

- (id)initWithSourceSectionInfo:(id<RZCollectionListSectionInfo>)sourceSectionInfo filteredList:(RZFilteredCollectionList*)filteredList;

@end

typedef enum {
    RZFilteredSourceListContentChangeStateNoChanges,
    RZFilteredSourceListContentChangeStatePotentialChanges,
    RZFilteredSourceListContentChangeStateChanged
} RZFilteredSourceListContentChangeState;

@interface RZFilteredCollectionList ()

@property (nonatomic, strong, readwrite) id<RZCollectionList> sourceList;

@property (nonatomic, strong) NSMutableIndexSet *sectionIndexes;
@property (nonatomic, strong) NSMutableArray    *objectIndexesForSection;

@property (nonatomic, strong) NSArray           *cachedSourceSections;
@property (nonatomic, strong) NSIndexSet        *cachedSectionIndexes;
@property (nonatomic, strong) NSArray           *cachedObjectIndexesForSectionShallow;
@property (nonatomic, strong) NSArray           *cachedObjectIndexesForSectionDeep;

@property (nonatomic, strong) NSMutableArray    *potentialObjectMoves;

@property (nonatomic, assign) RZFilteredSourceListContentChangeState contentChangeState;

@property (nonatomic, assign) BOOL isTransformingForPredicateChange;

- (void)setupIndexSetsForSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate;

- (NSIndexPath*)sourceIndexPathForIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath*)indexPath cached:(BOOL)cached;
- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section;
- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section cached:(BOOL)cached;

- (NSArray*)filteredSections;
- (NSArray*)filteredCachedSections;
- (NSArray*)filteredObjectsForSection:(RZFilteredCollectionListSectionInfo*)sectionInfo;
- (NSArray*)filteredObjects;

- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath*)sourceIndexPath;
- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath*)sourceIndexPath cached:(BOOL)cached;

// Mutation helpers
- (void)addSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)removeSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)updateSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath currentSourceIndexPath:(NSIndexPath*)currentIndexPath;

// moves must be done in two stages in a batch updaet
- (void)removeObjectForMoveNotification:(RZCollectionListObjectNotification*)moveNotification;
- (void)addObjectForMoveNotification:(RZCollectionListObjectNotification*)moveNotification;

- (void)filterOutSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)unfilterSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;

- (void)transformListForOldObjects:(NSArray*)oldObjects andNewObjects:(NSArray*)newObjects;

- (void)processReceivedChangeNotifications;

- (void)beginPotentialUpdates;
- (void)confirmPotentialUpdates;
- (void)endPotentialUpdates;

@end

@implementation RZFilteredCollectionList
@synthesize delegate = _delegate;

- (id)initWithSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate *)predicate
{
    if ((self = [super init]))
    {
        self.contentChangeState = RZFilteredSourceListContentChangeStateNoChanges;
        [self setupIndexSetsForSourceList:sourceList predicate:predicate];
        
        self.sourceList = sourceList;
        self.predicate = predicate;
        
        [self.sourceList addCollectionListObserver:self];
    }
    
    return self;
}

- (void)dealloc
{
    [self.sourceList removeCollectionListObserver:self];
}

- (void)setPredicate:(NSPredicate *)predicate
{
    if (predicate != _predicate)
    {
        NSMutableIndexSet *newSectionIndexes = nil;
        NSMutableArray *newObjectIndexes = nil;
        
        [self getIndexSets:&newObjectIndexes andSections:&newSectionIndexes forSourceList:self.sourceList predicate:predicate];
        
        _predicate = predicate;
        
        [self transformListForOldObjects:self.objectIndexesForSection andNewObjects:newObjectIndexes];
    }
}

- (void)setupIndexSetsForSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate
{
    NSMutableIndexSet *sectionIndexes = nil;
    NSMutableArray *objectIndexesForSection = nil;
    
    [self getIndexSets:&objectIndexesForSection andSections:&sectionIndexes forSourceList:sourceList predicate:predicate];
    
    self.sectionIndexes = sectionIndexes;
    self.objectIndexesForSection = objectIndexesForSection;
}

- (void)getIndexSets:(NSMutableArray*__autoreleasing*)objectsIndexes andSections:(NSMutableIndexSet*__autoreleasing*)sectionIdxs forSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate
{
    NSArray *sections = sourceList.sections;
    
    NSMutableIndexSet *sectionIndexes = [NSMutableIndexSet indexSet];
    NSMutableArray *objectIndexesForSection = [NSMutableArray arrayWithCapacity:[sections count]];
    
    [sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<RZCollectionListSectionInfo> section = (id<RZCollectionListSectionInfo>)obj;
        NSArray *objects = section.objects;
        
        NSIndexSet *objectIndexes = [objects indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return (nil == predicate) ? YES : [predicate evaluateWithObject:obj];
        }];
        
        [objectIndexesForSection addObject:[objectIndexes mutableCopy]];
        
        if ([objectIndexes count] > 0)
        {
            [sectionIndexes addIndex:idx];
        }
    }];
    
    if (nil != objectsIndexes)
    {
        *objectsIndexes = objectIndexesForSection;
    }
    
    if (nil != sectionIdxs)
    {
        *sectionIdxs = sectionIndexes;
    }
}

- (void)transformListForOldObjects:(NSArray*)oldObjects andNewObjects:(NSArray*)newObjects
{
    NSAssert([oldObjects count] == [newObjects count], @"There must be the same number of source sections.");
    
    NSMutableArray *removedObjects = [NSMutableArray arrayWithCapacity:oldObjects.count];
    NSMutableArray *addedObjects = [NSMutableArray arrayWithCapacity:oldObjects.count];
    NSMutableArray *updatedObjects = [NSMutableArray arrayWithCapacity:oldObjects.count];
    
    NSUInteger sections = [newObjects count];
    
    for (NSUInteger i = 0; i < sections; ++i)
    {
        NSIndexSet *oldObjectIndexes = [oldObjects objectAtIndex:i];
        NSIndexSet *newObjectIndexes = [newObjects objectAtIndex:i];
        
        NSIndexSet *removedObjectIndexes = [oldObjectIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
            return ![newObjectIndexes containsIndex:idx];
        }];
        NSIndexSet *addedObjectIndexes = [newObjectIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
            return ![oldObjectIndexes containsIndex:idx];
        }];
        NSIndexSet *updatedObjectIndexes = [newObjectIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
            return [oldObjectIndexes containsIndex:idx];
        }];
        
        [removedObjects addObject:removedObjectIndexes];
        [addedObjects addObject:addedObjectIndexes];
        [updatedObjects addObject:updatedObjectIndexes];
    }
    
    self.isTransformingForPredicateChange = YES;
    
    [self beginPotentialUpdates];
    
    [removedObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger section, BOOL *stop) {
        NSIndexSet *objectIndexes = (NSIndexSet*)obj;
        
        [objectIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger row, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            id object = [self.sourceList objectAtIndexPath:indexPath];
            
            [self filterOutSourceObject:object atSourceIndexPath:indexPath];
        }];
    }];
    
    [addedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger section, BOOL *stop) {
        NSIndexSet *objectIndexes = (NSIndexSet*)obj;
        
        [objectIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            id object = [self.sourceList objectAtIndexPath:indexPath];
            
            [self unfilterSourceObject:object atSourceIndexPath:indexPath];
        }];
    }];
    
    [self endPotentialUpdates];
}

- (NSIndexPath*)sourceIndexPathForIndexPath:(NSIndexPath*)indexPath
{
    __block NSUInteger sourceSection = 0;
    __block NSUInteger sectionCount = 0;
    [self.sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (sectionCount >= indexPath.section)
        {
            sourceSection = idx;
            *stop = YES;
        }
        
        ++sectionCount;
    }];
    
    NSIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:sourceSection];
    
    __block NSUInteger sourceItem = 0;
    __block NSUInteger itemCount = 0;
    [sectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (itemCount >= indexPath.row)
        {
            sourceItem = idx;
            *stop = YES;
        }
        
        ++itemCount;
    }];
    
    
    return [NSIndexPath indexPathForRow:sourceItem inSection:sourceSection];
}

- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath *)indexPath
{
    return [self filteredIndexPathForSourceIndexPath:indexPath cached:NO];
}

- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath*)indexPath cached:(BOOL)cached
{
    NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section cached:cached];
    
    NSIndexSet *sectionIndexSet = cached ? [self.cachedObjectIndexesForSectionDeep objectAtIndex:indexPath.section] : [self.objectIndexesForSection objectAtIndex:indexPath.section];
    NSUInteger filteredRow = [sectionIndexSet countOfIndexesInRange:NSMakeRange(0, indexPath.row)];
    
    return [NSIndexPath indexPathForRow:filteredRow inSection:filteredSection];
}

- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section
{
    return [self filteredSectionIndexForSourceSectionIndex:section cached:NO];
}

- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section cached:(BOOL)cached
{
    return cached ? [self.cachedSectionIndexes countOfIndexesInRange:NSMakeRange(0, section)] : [self.sectionIndexes countOfIndexesInRange:NSMakeRange(0, section)];
}

- (NSArray*)filteredSections
{
    NSArray *sourceSections = [self.sourceList.sections objectsAtIndexes:self.sectionIndexes];
    NSMutableArray *filteredSections = [NSMutableArray arrayWithCapacity:sourceSections.count];
    
    [sourceSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<RZCollectionListSectionInfo> sourceSection = (id<RZCollectionListSectionInfo>)obj;
        RZFilteredCollectionListSectionInfo *filteredSection = [[RZFilteredCollectionListSectionInfo alloc] initWithSourceSectionInfo:sourceSection filteredList:self];
        
        [filteredSections addObject:filteredSection];
    }];
    
    return filteredSections;
}

- (NSArray*)filteredCachedSections
{
    NSArray *sourceSections = [self.cachedSourceSections objectsAtIndexes:self.sectionIndexes];
    NSMutableArray *filteredSections = [NSMutableArray arrayWithCapacity:sourceSections.count];
    
    [sourceSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<RZCollectionListSectionInfo> sourceSection = (id<RZCollectionListSectionInfo>)obj;
        RZFilteredCollectionListSectionInfo *filteredSection = [[RZFilteredCollectionListSectionInfo alloc] initWithSourceSectionInfo:sourceSection filteredList:self];
        
        [filteredSections addObject:filteredSection];
    }];
    
    return filteredSections;
}

- (NSArray*)filteredObjectsForSection:(RZFilteredCollectionListSectionInfo*)sectionInfo
{
    NSUInteger sourceSectionIndex = [self.sourceList.sections indexOfObject:sectionInfo.sourceSectionInfo];
    
    if (sourceSectionIndex == NSNotFound)
    {
        sourceSectionIndex = [self.sourceList.sections indexOfObjectPassingTest:^BOOL(id<RZCollectionListSectionInfo> obj, NSUInteger idx, BOOL *stop) {
            BOOL found = (obj.name == sectionInfo.name || [obj.name isEqualToString:sectionInfo.name]);
            
            if (found)
            {
                *stop = YES;
            }
            
            return found;
        }];
    }
    
    NSArray *filteredObjects = nil;
    
    if (sourceSectionIndex != NSNotFound)
    {
        NSIndexSet *indexesOfSectionObjects = [self.objectIndexesForSection objectAtIndex:sourceSectionIndex];
        filteredObjects = [sectionInfo.sourceSectionInfo.objects objectsAtIndexes:indexesOfSectionObjects];
    }
    
    return filteredObjects;
}

- (NSArray*)filteredObjects
{
    NSMutableArray *filteredObjects = [NSMutableArray array];
    NSArray *filteredSections = [self filteredSections];
    
    [filteredSections enumerateObjectsUsingBlock:^(RZFilteredCollectionListSectionInfo *section, NSUInteger idx, BOOL *stop) {
        [filteredObjects addObjectsFromArray:section.objects];
    }];
    
    return filteredObjects;
}

- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath *)sourceIndexPath
{
    return [self sourceIndexPathIsInFilteredList:sourceIndexPath cached:NO];
}

- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath*)sourceIndexPath cached:(BOOL)cached
{
    BOOL isInFilteredList = NO;
    
    NSInteger section = sourceIndexPath.section;
    NSInteger row = sourceIndexPath.row;
    
    
    NSIndexSet *sectionIndexes = cached ? self.cachedSectionIndexes : self.sectionIndexes;
    
    if ([sectionIndexes containsIndex:section])
    {
        NSArray *objectIndexesForSection = cached ? self.cachedObjectIndexesForSectionDeep : self.objectIndexesForSection;
        
        if (section >= 0 && section < objectIndexesForSection.count)
        {
            NSIndexSet *objectIndexes = [objectIndexesForSection objectAtIndex:section];
            isInFilteredList = [objectIndexes containsIndex:row];
        }
    }
    
    return isInFilteredList;
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    return (self.predicate == nil ? [self.sourceList listObjects] : [self filteredObjects]);
}

- (NSArray*)sections
{
    return [self filteredSections];
}

- (NSArray*)listObservers
{
    return [self.collectionListObservers allObjects];
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
    NSIndexPath *sourceIndexPath = [self sourceIndexPathForIndexPath:indexPath];
    return [self.sourceList objectAtIndexPath:sourceIndexPath];
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    NSIndexPath *sourceIndexPath = [self.sourceList indexPathForObject:object];
    return [self filteredIndexPathForSourceIndexPath:sourceIndexPath];
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
        RZFilteredCollectionListSectionInfo *section = [filteredArray lastObject];
        
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

- (void)addSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        [sectionIndexSet shiftIndexesStartingAtIndex:indexPath.row by:1];
        
        if ([self.predicate evaluateWithObject:object] || nil == self.predicate)
        {
            [self confirmPotentialUpdates];
            
            if (![self.sectionIndexes containsIndex:indexPath.section])
            {
                [self.sectionIndexes addIndex:indexPath.section];
                
                NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
                
                RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredSections] objectAtIndex:filteredSection];
                
                [self cacheSectionNotificationWithSectionInfo:filteredSectionInfo sectionIndex:filteredSection type:RZCollectionListChangeInsert];
                
            }
            
            [sectionIndexSet addIndex:indexPath.row];
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
            [self cacheObjectNotificationWithObject:object indexPath:nil newIndexPath:filteredIndexPath type:RZCollectionListChangeInsert];
        }
    }
}

- (void)removeSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.cachedObjectIndexesForSectionDeep.count && indexPath.section < self.objectIndexesForSection.count)
    {
        NSMutableIndexSet *cachedSectionIndexSet = [self.cachedObjectIndexesForSectionDeep objectAtIndex:indexPath.section];
        
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        [sectionIndexSet shiftIndexesStartingAtIndex:indexPath.row+1 by:-1];
        
        if ([cachedSectionIndexSet containsIndex:indexPath.row])
        {
            [self confirmPotentialUpdates];
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath cached:YES];
            [self cacheObjectNotificationWithObject:object indexPath:filteredIndexPath newIndexPath:nil type:RZCollectionListChangeDelete];
            
            if ([sectionIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
            {
                NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
                RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredCachedSections] objectAtIndex:filteredSection];
                
                [self.sectionIndexes removeIndex:indexPath.section];
                
                [self cacheSectionNotificationWithSectionInfo:filteredSectionInfo sectionIndex:filteredSection type:RZCollectionListChangeDelete];
                
            }
        }
    }
}

- (void)removeObjectForMoveNotification:(RZCollectionListObjectNotification*)moveNotification
{
    // All we need to do here is remove the index from the set
    NSIndexPath *indexPath = moveNotification.indexPath;
    NSUInteger sectionCount = self.objectIndexesForSection.count;
    if (indexPath.section >= 0 && indexPath.section < sectionCount)
    {
        NSMutableIndexSet *fromSectionObjectIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        
        // Remove fromIndex from fromSection
        [fromSectionObjectIndexSet shiftIndexesStartingAtIndex:indexPath.row+1 by:-1];
    }
}


- (void)addObjectForMoveNotification:(RZCollectionListObjectNotification*)moveNotification
{
    NSIndexPath *indexPath = moveNotification.indexPath;
    NSIndexPath *newIndexPath = moveNotification.nuIndexPath;
    NSUInteger sectionCount = self.objectIndexesForSection.count;
    if (newIndexPath.section >= 0 && newIndexPath.section < sectionCount)
    {
        BOOL isObjectInFilteredList = [self sourceIndexPathIsInFilteredList:indexPath cached:YES];

        // use shallow copy so we actually modify the current index set
        NSMutableIndexSet *fromSectionObjectIndexSet = [self.cachedObjectIndexesForSectionShallow objectAtIndex:indexPath.section];
        NSMutableIndexSet *toSectionObjectIndexSet = [self.objectIndexesForSection objectAtIndex:newIndexPath.section];

        NSIndexPath *fromFilteredIndexPath = nil;
        NSIndexPath *toFilteredIndexPath = nil;

        if (isObjectInFilteredList)
        {
            // Unfilter toSection and send Add Section Notification if toSection is filtered out
            if (![self.sectionIndexes containsIndex:newIndexPath.section])
            {
                [self confirmPotentialUpdates];

                [self.sectionIndexes addIndex:newIndexPath.section];

                NSUInteger toFilteredSection = [self filteredSectionIndexForSourceSectionIndex:newIndexPath.section];

                RZFilteredCollectionListSectionInfo *toFilteredSectionInfo = [[self filteredSections] objectAtIndex:toFilteredSection];

                [self cacheSectionNotificationWithSectionInfo:toFilteredSectionInfo sectionIndex:toFilteredSection type:RZCollectionListChangeInsert];
            }

            // With possible new section added get fromFilteredIndexPath
            fromFilteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath cached:YES];

        }
        
        // Make room at toIndex in toSection
        [toSectionObjectIndexSet shiftIndexesStartingAtIndex:newIndexPath.row by:1];

        if (isObjectInFilteredList)
        {
            // Unfilter toIndex if object is in filtered list
            [toSectionObjectIndexSet addIndex:newIndexPath.row];

            // Get new toFilteredIndexPath
            toFilteredIndexPath = [self filteredIndexPathForSourceIndexPath:newIndexPath];

            // If filtered from and to index paths are different, send out move notification
            if (![fromFilteredIndexPath isEqual:toFilteredIndexPath])
            {
                [self confirmPotentialUpdates];

                [self cacheObjectNotificationWithObject:moveNotification.object indexPath:fromFilteredIndexPath newIndexPath:toFilteredIndexPath type:RZCollectionListChangeMove];

                // Filter fromSection and send Remove Section Notification if fromSection has no objects remaining
                if ([fromSectionObjectIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
                {
                    NSUInteger fromFilteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
                    RZFilteredCollectionListSectionInfo *fromFilteredSectionInfo = [[self filteredCachedSections] objectAtIndex:fromFilteredSection];

                    [self.sectionIndexes removeIndex:indexPath.section];

                    [self cacheSectionNotificationWithSectionInfo:fromFilteredSectionInfo sectionIndex:fromFilteredSection type:RZCollectionListChangeDelete];
                }
            }
        }
    }
}

- (void)updateSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath currentSourceIndexPath:(NSIndexPath *)currentIndexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        BOOL isInFilteredList = [self sourceIndexPathIsInFilteredList:indexPath cached:YES];
        BOOL passesPredicate = ([self.predicate evaluateWithObject:object] || nil == self.predicate);
        
        if (passesPredicate && !isInFilteredList)
        {
            [self unfilterSourceObject:object atSourceIndexPath:currentIndexPath];
        }
        else if (!passesPredicate && isInFilteredList)
        {
            [self filterOutSourceObject:object atSourceIndexPath:currentIndexPath];
        }
        else if (passesPredicate && isInFilteredList)
        {
            [self confirmPotentialUpdates];
            
            NSIndexPath *prevFilteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath cached:YES];
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath cached:NO];
            
            [self cacheObjectNotificationWithObject:object indexPath:prevFilteredIndexPath newIndexPath:filteredIndexPath type:RZCollectionListChangeUpdate];
        }
    }
}

- (void)filterOutSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        
        if ([sectionIndexSet containsIndex:indexPath.row])
        {
            [self confirmPotentialUpdates];
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath cached:YES];
                        
            [self cacheObjectNotificationWithObject:object indexPath:filteredIndexPath newIndexPath:nil type:RZCollectionListChangeDelete];
        }
        
        [sectionIndexSet removeIndex:indexPath.row];
        
        if ([sectionIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
        {
            NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
            RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredCachedSections] objectAtIndex:filteredSection];
            
            [self.sectionIndexes removeIndex:indexPath.section];
            
            [self cacheSectionNotificationWithSectionInfo:filteredSectionInfo sectionIndex:filteredSection type:RZCollectionListChangeDelete];
            
        }
    }
}

- (void)unfilterSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        [self confirmPotentialUpdates];
        
        if (![self.sectionIndexes containsIndex:indexPath.section])
        {
            [self.sectionIndexes addIndex:indexPath.section];
            
            NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
            
            RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredSections] objectAtIndex:filteredSection];
            
            [self cacheSectionNotificationWithSectionInfo:filteredSectionInfo sectionIndex:filteredSection type:RZCollectionListChangeInsert];
            
        }
        
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        [sectionIndexSet addIndex:indexPath.row];
        
        NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
        
        [self cacheObjectNotificationWithObject:object indexPath:nil newIndexPath:filteredIndexPath type:RZCollectionListChangeInsert];
    }
}


- (void)beginPotentialUpdates
{
    self.contentChangeState = RZFilteredSourceListContentChangeStatePotentialChanges;
    self.cachedSourceSections = [self.sourceList.sections copy];
    self.cachedSectionIndexes = [self.sectionIndexes copy];
    self.cachedObjectIndexesForSectionShallow = [self.objectIndexesForSection copy];
    self.cachedObjectIndexesForSectionDeep = [[NSMutableArray alloc] initWithArray:self.objectIndexesForSection copyItems:YES];
}

- (void)confirmPotentialUpdates
{
    if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }
    
    self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
}

- (void)endPotentialUpdates
{
    if (!self.isTransformingForPredicateChange){
        [self processReceivedChangeNotifications];
    }
    
    if (self.contentChangeState == RZFilteredSourceListContentChangeStateChanged)
    {
        // deliver outgoing notifications
        [self sendAllPendingChangeNotifications];
        [self sendDidChangeContentNotifications];
    }
    
    [self resetPendingNotifications];
    self.contentChangeState = RZFilteredSourceListContentChangeStateNoChanges;
    self.isTransformingForPredicateChange = NO;
    self.cachedSourceSections = nil;
    self.cachedSectionIndexes = nil;
    self.cachedObjectIndexesForSectionDeep = nil;
    self.cachedObjectIndexesForSectionShallow = nil;
}

- (void)processReceivedChangeNotifications
{
    // -- Make local copies of received notification caches --
    
    // -- Section
    NSArray *sectionRemoveNotifications = [self.pendingSectionRemoveNotifications copy];
    NSArray *sectionInsertNotifications = [self.pendingSectionInsertNotifications copy];
    
    // -- Object
    NSArray *objectRemoveNotifications   = [self.pendingObjectRemoveNotifications copy];
    NSArray *objectInsertNotifications   = [self.pendingObjectInsertNotifications copy];
    
    NSArray *objectMoveNotifications     = [self.pendingObjectMoveNotifications copy];
    NSArray *objectUpdateNotifications   = [self.pendingObjectUpdateNotifications copy];
    
    // -- clear cache in prep for outgoing notifications --
    
    [self resetPendingNotifications];
    
    // -- process incoming notifications - mutate internal state and produce cached outgoing notifications --
    
    [objectRemoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self removeSourceObject:notification.object atSourceIndexPath:notification.indexPath];
    }];
    
    // First half of move (remove object)
    [objectMoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self removeObjectForMoveNotification:notification];
    }];
    
    [sectionRemoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListSectionNotification *notification, NSUInteger idx, BOOL *stop) {
        [self.sectionIndexes shiftIndexesStartingAtIndex:notification.sectionIndex+1 by:-1];
        [self.objectIndexesForSection removeObjectAtIndex:notification.sectionIndex];
    }];
    
    [sectionInsertNotifications enumerateObjectsUsingBlock:^(RZCollectionListSectionNotification *notification, NSUInteger idx, BOOL *stop) {
        [self.sectionIndexes shiftIndexesStartingAtIndex:notification.sectionIndex by:1];
        [self.objectIndexesForSection insertObject:[NSMutableIndexSet indexSet] atIndex:notification.sectionIndex];
    }];
    
    [objectInsertNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self addSourceObject:notification.object atSourceIndexPath:notification.nuIndexPath];
    }];
    
    // Second half of move (insert object)
    [objectMoveNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self addObjectForMoveNotification:notification];
    }];

    [objectUpdateNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self updateSourceObject:notification.object atSourceIndexPath:notification.indexPath currentSourceIndexPath:notification.nuIndexPath];
    }];
    
    // -- Update all new index paths for any operations which may have changed them --
    
    [self.pendingObjectInsertNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        
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

/***************************************************************************************************
 *
 *  The batch mutation strategy is a bit complicated here. This is the gist:
 *
 *  1) When "willChange" notification is received, create copies of the current
 *     index sets and source section indexes.
 *
 *  2) Cache each incoming object/section change notification, but take no other action yet.
 *
 *  3) When "didChange" notification is received, create local copies of cached notifications and
 *     clear the notification cache in preparation for outgoing notifications
 *  
 *  4) Enumerate the received notifications in order (removal, insert, move, update) and mutate the
 *     internal state. If an outgoing notification is produced, cache it.
 *
 *     -- To preserve causality in the internal index sets, object move notifications need to be split 
 *      into two phases - remove and then re-insert - which are performed immediately after the normal 
 *      remove/insert mutations. See comments inline with code for details
 *
 *  5) Enumerate all outgoing notifications that produce an insert (insert and move) and update the
 *      newIndexPath to account for other insertions that may have offset them.
 *
 *  6) Send out all cached outgoing notifications.
 *
 ***************************************************************************************************/

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    [self cacheObjectNotificationWithObject:object indexPath:indexPath newIndexPath:newIndexPath type:type];
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    [self cacheSectionNotificationWithSectionInfo:sectionInfo sectionIndex:sectionIndex type:type];
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

@implementation RZFilteredCollectionListSectionInfo

- (id)initWithSourceSectionInfo:(id<RZCollectionListSectionInfo>)sourceSectionInfo filteredList:(RZFilteredCollectionList*)filteredList
{
    if ((self = [super init]))
    {
        self.sourceSectionInfo = sourceSectionInfo;
        self.filteredList = filteredList;
    }
    
    return self;
}

- (NSString*)name
{
    return self.sourceSectionInfo.name;
}

- (NSString*)indexTitle
{
    return self.sourceSectionInfo.indexTitle;
}

- (NSUInteger)numberOfObjects
{
    return [self.objects count];
}

- (NSArray*)objects
{
    return [self.filteredList filteredObjectsForSection:self];
}

@end
