//
//  RZFilteredCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/12/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZFilteredCollectionList.h"
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
@property (nonatomic, strong) NSMutableArray *objectIndexesForSection;
@property (nonatomic, strong) NSArray *cachedSourceSections;

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

@property (nonatomic, assign) RZFilteredSourceListContentChangeState contentChangeState;

- (void)setupIndexSetsForSourceList:(id<RZCollectionList>)sourceList predicate:(NSPredicate*)predicate;

- (NSIndexPath*)sourceIndexPathForIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath*)indexPath;
- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section;
- (NSArray*)filteredSections;
- (NSArray*)filteredCachedSections;
- (NSArray*)filteredObjectsForSection:(RZFilteredCollectionListSectionInfo*)sectionInfo;
- (NSArray*)filteredObjects;

- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath*)sourceIndexPath;

// Mutation helpers
- (void)addSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)removeSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)moveSourceObject:(id)object fromSourceIndexPath:(NSIndexPath*)indexPath toSourceIndexPath:(NSIndexPath*)newIndexPath;
- (void)updateSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;

- (void)filterOutSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;
- (void)unfilterSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath;

- (void)beginPotentialUpdates;
- (void)endPotentialUpdates;

// Notification helpers
- (void)sendWillChangeContentNotifications;
- (void)sendDidChangeContentNotifications;
- (void)sendDidChangeObjectNotification:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;
- (void)sendDidChangeSectionNotification:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex  forChangeType:(RZCollectionListChangeType)type;

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

- (RZObserverCollection*)collectionListObservers
{
    if (nil == _collectionListObservers)
    {
        _collectionListObservers = [[RZObserverCollection alloc] init];
    }
    
    return _collectionListObservers;
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

- (NSIndexPath*)filteredIndexPathForSourceIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
    
    NSIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
    NSUInteger filteredRow = [sectionIndexSet countOfIndexesInRange:NSMakeRange(0, indexPath.row)];
    
    return [NSIndexPath indexPathForRow:filteredRow inSection:filteredSection];
}

- (NSUInteger)filteredSectionIndexForSourceSectionIndex:(NSUInteger)section
{
    return [self.sectionIndexes countOfIndexesInRange:NSMakeRange(0, section)];
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

- (BOOL)sourceIndexPathIsInFilteredList:(NSIndexPath*)sourceIndexPath
{
    BOOL isInFilteredList = NO;
    
    NSInteger section = sourceIndexPath.section;
    NSInteger row = sourceIndexPath.row;
    
    if ([self.sectionIndexes containsIndex:section])
    {
        if (section >= 0 && section < self.objectIndexesForSection.count)
        {
            NSIndexSet *objectIndexes = [self.objectIndexesForSection objectAtIndex:section];
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

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
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
            if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
            {
                [self sendWillChangeContentNotifications];
            }
            
            self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
            
            if (![self.sectionIndexes containsIndex:indexPath.section])
            {
                [self.sectionIndexes addIndex:indexPath.section];
                
                NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
                
                RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredSections] objectAtIndex:filteredSection];
                
                [self sendDidChangeSectionNotification:filteredSectionInfo atIndex:filteredSection forChangeType:RZCollectionListChangeInsert];
            }
            
            [sectionIndexSet addIndex:indexPath.row];
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
            
            [self sendDidChangeObjectNotification:object atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:filteredIndexPath];
        }
    }
}

- (void)removeSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        
        if ([sectionIndexSet containsIndex:indexPath.row])
        {
            if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
            {
                [self sendWillChangeContentNotifications];
            }
            
            self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
            
            [sectionIndexSet shiftIndexesStartingAtIndex:indexPath.row+1 by:-1];
            
            [self sendDidChangeObjectNotification:object atIndexPath:filteredIndexPath forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
        }
        else
        {
            [sectionIndexSet shiftIndexesStartingAtIndex:indexPath.row+1 by:-1];
        }
        
        if ([sectionIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
        {
            NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
            RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredCachedSections] objectAtIndex:filteredSection];
            
            [self.sectionIndexes removeIndex:indexPath.section];
            
            [self sendDidChangeSectionNotification:filteredSectionInfo atIndex:filteredSection forChangeType:RZCollectionListChangeDelete];
        }
    }
}

- (void)moveSourceObject:(id)object fromSourceIndexPath:(NSIndexPath*)indexPath toSourceIndexPath:(NSIndexPath*)newIndexPath
{
    
}

- (void)updateSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        BOOL isInFilteredList = [self sourceIndexPathIsInFilteredList:indexPath];
        BOOL passesPredicate = ([self.predicate evaluateWithObject:object] || nil == self.predicate);
        
        if (passesPredicate && !isInFilteredList)
        {
            [self unfilterSourceObject:object atSourceIndexPath:indexPath];
        }
        else if (!passesPredicate && isInFilteredList)
        {
            [self filterOutSourceObject:object atSourceIndexPath:indexPath];
        }
        else if (passesPredicate && isInFilteredList)
        {
            if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
            {
                [self sendWillChangeContentNotifications];
            }
            
            self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
            
            [self sendDidChangeObjectNotification:object atIndexPath:filteredIndexPath forChangeType:RZCollectionListChangeUpdate newIndexPath:nil];
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
            if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
            {
                [self sendWillChangeContentNotifications];
            }
            
            self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
            
            NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
            
            [sectionIndexSet removeIndex:indexPath.row];
            
            [self sendDidChangeObjectNotification:object atIndexPath:filteredIndexPath forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
        }
        else
        {
            [sectionIndexSet removeIndex:indexPath.row];
        }
        
        if ([sectionIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
        {
            NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
            RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredCachedSections] objectAtIndex:filteredSection];
            
            [self.sectionIndexes removeIndex:indexPath.section];
            
            [self sendDidChangeSectionNotification:filteredSectionInfo atIndex:filteredSection forChangeType:RZCollectionListChangeDelete];
        }
    }
}

- (void)unfilterSourceObject:(id)object atSourceIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section >= 0 && indexPath.section < self.objectIndexesForSection.count)
    {
        if (self.contentChangeState == RZFilteredSourceListContentChangeStatePotentialChanges)
        {
            [self sendWillChangeContentNotifications];
        }
        
        self.contentChangeState = RZFilteredSourceListContentChangeStateChanged;
        
        if (![self.sectionIndexes containsIndex:indexPath.section])
        {
            [self.sectionIndexes addIndex:indexPath.section];
            
            NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
            
            RZFilteredCollectionListSectionInfo *filteredSectionInfo = [[self filteredSections] objectAtIndex:filteredSection];
            
            [self sendDidChangeSectionNotification:filteredSectionInfo atIndex:filteredSection forChangeType:RZCollectionListChangeInsert];
        }
        
        NSMutableIndexSet *sectionIndexSet = [self.objectIndexesForSection objectAtIndex:indexPath.section];
        [sectionIndexSet addIndex:indexPath.row];
        
        NSIndexPath *filteredIndexPath = [self filteredIndexPathForSourceIndexPath:indexPath];
        
        [self sendDidChangeObjectNotification:object atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:filteredIndexPath];
    }
}

- (void)beginPotentialUpdates
{
    self.contentChangeState = RZFilteredSourceListContentChangeStatePotentialChanges;
    self.cachedSourceSections = [self.sourceList.sections copy];
}

- (void)endPotentialUpdates
{
    if (self.contentChangeState == RZFilteredSourceListContentChangeStateChanged)
    {
        [self sendDidChangeContentNotifications];
    }
    
    self.contentChangeState = RZFilteredSourceListContentChangeStateNoChanges;
    self.cachedSourceSections = nil;
}

#pragma mark - Notification Helpers

- (void)sendWillChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZFilteredCollectionList Will Change");
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
    NSLog(@"RZFilteredCollectionList Did Change");
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
    NSLog(@"RZFilteredCollectionList Did Change Object: %@ IndexPath:%@ Type: %d NewIndexPath: %@", object, indexPath, type, newIndexPath);
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
    NSLog(@"RZFilteredCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
#endif
    [[self.collectionListObservers allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionList:self didChangeSection:sectionInfo atIndex:sectionIndex forChangeType:type];
        }
    }];
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    switch(type) {
        case RZCollectionListChangeInsert:
            [self addSourceObject:object atSourceIndexPath:newIndexPath];
            break;
        case RZCollectionListChangeDelete:
            [self removeSourceObject:object atSourceIndexPath:indexPath];
            break;
        case RZCollectionListChangeMove:
            [self moveSourceObject:object fromSourceIndexPath:indexPath toSourceIndexPath:newIndexPath];
            break;
        case RZCollectionListChangeUpdate:
            [self updateSourceObject:object atSourceIndexPath:indexPath];
            break;
        default:
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    switch(type) {
        case RZCollectionListChangeInsert:
            [self.sectionIndexes shiftIndexesStartingAtIndex:sectionIndex by:1];
            [self.objectIndexesForSection insertObject:[NSMutableIndexSet indexSet] atIndex:sectionIndex];
            break;
        case RZCollectionListChangeDelete:
            [self.sectionIndexes shiftIndexesStartingAtIndex:sectionIndex+1 by:-1];
            [self.objectIndexesForSection removeObjectAtIndex:sectionIndex];
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
