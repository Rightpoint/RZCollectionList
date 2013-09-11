//
//  RZCompositeCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCompositeCollectionList.h"
#import "RZBaseCollectionList_Private.h"
#import "RZObserverCollection.h"

@interface RZCompositeCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *indexTitle;

@property (nonatomic, assign, readwrite) NSUInteger numberOfObjects;
@property (nonatomic, strong, readwrite) NSArray *objects;

@property (nonatomic, assign) BOOL isCachedCopy;

@property (nonatomic, weak) RZCompositeCollectionList *compositeList;

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle compositeList:(RZCompositeCollectionList*)compositeList;

@end

typedef enum {
    RZCompositeSourceListContentChangeStateNoChanges,
    RZCompositeSourceListContentChangeStatePotentialChanges,
    RZCompositeSourceListContentChangeStateChanged
} RZCompositeSourceListContentChangeState;

@interface RZCompositeCollectionList ()

@property (nonatomic, readwrite, copy) NSArray *sourceLists;

@property (nonatomic, strong) NSMutableArray *sourceListSectionRanges;
@property (nonatomic, strong) NSMutableArray *sourceListForSection;
@property (nonatomic, strong) NSArray *cachedSourceListSectionRanges;
@property (nonatomic, strong) NSArray *cachedSourceListSections;

@property (nonatomic, assign) BOOL ignoreSections;
@property (nonatomic, strong) RZCompositeCollectionListSectionInfo *singleSectionInfo;
@property (nonatomic, strong) RZCompositeCollectionListSectionInfo *cachedSingleSectionInfo;
@property (nonatomic, assign) RZCompositeSourceListContentChangeState contentChangeState;

- (void)configureSectionsWithSourceLists:(NSArray*)sourceLists;

// Section Helpers
- (void)addSectionForSourceList:(id<RZCollectionList>)sourceList;
- (void)removeSectionForSourceList:(id<RZCollectionList>)sourceList;

// Update Helpers
- (void)beginPotentialUpdatesFromList:(id<RZCollectionList>)updatingList;
- (void)confirmPotentialUpdates;
- (void)endPotentialUpdates;

- (void)translateObjectNotification:(RZCollectionListObjectNotification*)notification;
- (void)translateSectionNotification:(RZCollectionListSectionNotification*)notification;

- (void)processReceivedChangeNotifications;

@end

@implementation RZCompositeCollectionList

- (id)initWithSourceLists:(NSArray*)sourceLists
{
    return [self initWithSourceLists:sourceLists ignoreSections:NO];
}

- (id)initWithSourceLists:(NSArray*)sourceLists ignoreSections:(BOOL)ignoreSections
{
    if ((self = [super init]))
    {
        self.sourceLists = sourceLists;
        self.ignoreSections = ignoreSections;
        self.singleSectionInfo = [[RZCompositeCollectionListSectionInfo alloc] initWithName:nil sectionIndexTitle:nil compositeList:self];
    }
    
    return self;
}

- (id<RZCollectionList>)sourceListForSectionIndex:(NSUInteger)sectionIndex
{
    id <RZCollectionList> sourceList = nil;
    if (sectionIndex < self.sourceListForSection.count){
        sourceList = [self.sourceLists objectAtIndex:[[self.sourceListForSection objectAtIndex:sectionIndex] unsignedIntegerValue]];
    }
    return sourceList;
}

- (void)configureSectionsWithSourceLists:(NSArray*)sourceLists
{
    NSMutableArray *sectionRanges = [[NSMutableArray alloc] initWithCapacity:sourceLists.count];
    NSMutableArray *sectionMap = [[NSMutableArray alloc] init];
    
    __block NSUInteger currentSection = 0;
    
    [sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id <RZCollectionList> list = (id<RZCollectionList>)obj;
        
        NSArray *sections = list.sections;
        NSUInteger numberOfSections = [sections count];
        
        NSRange sectionRange = NSMakeRange(currentSection, numberOfSections);
        currentSection += numberOfSections;
        
        [sectionRanges addObject:[NSValue valueWithRange:sectionRange]];
        
        NSNumber *currentIndex = [NSNumber numberWithUnsignedInteger:idx];
        for (int i=0; i < numberOfSections; ++i)
        {
            [sectionMap addObject:currentIndex];
        }
    }];
    
    self.sourceListSectionRanges = sectionRanges;
    self.sourceListForSection = sectionMap;
}

- (void)addSectionForSourceList:(id<RZCollectionList>)sourceList
{
    NSUInteger indexForSourceList = [self.sourceLists indexOfObject:sourceList];
    NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexForSourceList] rangeValue];
    NSValue *rangeValue = [NSValue valueWithRange:NSMakeRange(sourceListSectionRange.location, sourceListSectionRange.length+1)];
    [self.sourceListSectionRanges replaceObjectAtIndex:indexForSourceList withObject:rangeValue];
    [self.sourceListForSection insertObject:[NSNumber numberWithUnsignedInteger:indexForSourceList] atIndex:sourceListSectionRange.location];
    
    NSUInteger startModRange = indexForSourceList + 1;
    NSIndexSet *rangesToModify = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startModRange, self.sourceListSectionRanges.count - startModRange)];
    
    __block NSMutableArray *sourceListSectionRangesCopy = [self.sourceListSectionRanges mutableCopy];
    [self.sourceListSectionRanges enumerateObjectsAtIndexes:rangesToModify options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSValue *newRangeValue = [NSValue valueWithRange:NSMakeRange(range.location+1, range.length)];
        [sourceListSectionRangesCopy replaceObjectAtIndex:idx withObject:newRangeValue];
    }];
    self.sourceListSectionRanges = sourceListSectionRangesCopy;
}

- (void)removeSectionForSourceList:(id<RZCollectionList>)sourceList
{
    NSUInteger indexForSourceList = [self.sourceLists indexOfObject:sourceList];
    NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexForSourceList] rangeValue];
    NSValue *rangeValue = [NSValue valueWithRange:NSMakeRange(sourceListSectionRange.location, sourceListSectionRange.length-1)];
    [self.sourceListSectionRanges replaceObjectAtIndex:indexForSourceList withObject:rangeValue];
    [self.sourceListForSection removeObjectAtIndex:sourceListSectionRange.location];
    
    NSUInteger startModRange = indexForSourceList + 1;
    NSIndexSet *rangesToModify = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startModRange, self.sourceListSectionRanges.count - startModRange)];

    __block NSMutableArray *sourceListSectionRangesCopy = [self.sourceListSectionRanges mutableCopy];
    [self.sourceListSectionRanges enumerateObjectsAtIndexes:rangesToModify options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSValue *newRangeValue = [NSValue valueWithRange:NSMakeRange(range.location-1, range.length)];
        [sourceListSectionRangesCopy replaceObjectAtIndex:idx withObject:newRangeValue];
    }];
    self.sourceListSectionRanges = sourceListSectionRangesCopy;
}

- (void)translateObjectNotification:(RZCollectionListObjectNotification *)notification
{
    
    NSIndexPath *modifiedIndexPath = nil;
    NSIndexPath *modifiedNewIndexPath = nil;
    NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:notification.sourceList];
    
    if (self.ignoreSections)
    {
        __block NSUInteger oldRowOffset = 0;
        __block NSUInteger newRowOffset = 0;

        // find old index path based on original object counts
        if (nil != notification.indexPath)
        {
            [self.cachedSourceListSections enumerateObjectsUsingBlock:^(NSArray *sourceSections, NSUInteger listIdx, BOOL *listStop) {
                
                if (listIdx == indexOfSourceList)
                {
                    [sourceSections enumerateObjectsUsingBlock:^(id<RZCollectionListSectionInfo> sectionInfo, NSUInteger sectionIdx, BOOL *sectionStop) {
                        if (sectionIdx == notification.indexPath.section)
                        {
                            *sectionStop = YES;
                        }
                        else
                        {
                            oldRowOffset += [sectionInfo numberOfObjects];
                        }
                    }];
                    
                    *listStop = YES;
                }
                else
                {
                    oldRowOffset += [[sourceSections valueForKeyPath:@"@sum.numberOfObjects"] unsignedIntegerValue];
                }
            }];
            
        }
        
        if (nil != notification.nuIndexPath)
        {
            [self.sourceLists enumerateObjectsUsingBlock:^(id<RZCollectionList> sourceList, NSUInteger listIdx, BOOL *listStop) {
                if (listIdx == indexOfSourceList)
                {
                    [sourceList.sections enumerateObjectsUsingBlock:^(id<RZCollectionListSectionInfo> section, NSUInteger sectionIdx, BOOL *sectionStop) {
                        if (sectionIdx == notification.nuIndexPath.section)
                        {
                            *sectionStop = YES;
                        }
                        else
                        {
                            newRowOffset += section.numberOfObjects;
                        }
                    }];
                    *listStop = YES;
                }
                else
                {
                    newRowOffset += sourceList.listObjects.count;
                }
            }];

        }
        

        modifiedIndexPath = (notification.indexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.indexPath.row + oldRowOffset inSection:0];
        modifiedNewIndexPath = (notification.nuIndexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.nuIndexPath.row + newRowOffset inSection:0];

    }
    else
    {
        NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        NSRange sourceListSectionRangeCached = [[self.cachedSourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        
        modifiedIndexPath = (notification.indexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.indexPath.row inSection:notification.indexPath.section + sourceListSectionRangeCached.location];
        modifiedNewIndexPath = (notification.nuIndexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.nuIndexPath.row inSection:notification.nuIndexPath.section + sourceListSectionRange.location];
        
    }
    
    notification.indexPath = modifiedIndexPath;
    notification.nuIndexPath = modifiedNewIndexPath;
}

- (void)translateSectionNotification:(RZCollectionListSectionNotification *)notification
{
    NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:notification.sourceList];
    
    if (notification.type == RZCollectionListChangeInsert)
    {
        NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        notification.sectionIndex += sourceListSectionRange.location;
    }
    else if (notification.type == RZCollectionListChangeDelete)
    {
        NSRange sourceListSectionRange = [[self.cachedSourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        notification.sectionIndex += sourceListSectionRange.location;
    }
}

- (void)processReceivedChangeNotifications
{
    [self.allPendingSectionNotifications enumerateObjectsUsingBlock:^(RZCollectionListSectionNotification *notification, NSUInteger idx, BOOL *stop) {
        
        [self translateSectionNotification:notification];
        
        if (notification.type == RZCollectionListChangeDelete)
        {
            [self removeSectionForSourceList:notification.sourceList];
        }
        else if (notification.type == RZCollectionListChangeInsert)
        {
            [self addSectionForSourceList:notification.sourceList];
        }
        
    }];
    
    [self.allPendingObjectNotifications enumerateObjectsUsingBlock:^(RZCollectionListObjectNotification *notification, NSUInteger idx, BOOL *stop) {
        [self translateObjectNotification:notification];
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

#pragma mark - Property Overrides

- (void)setSourceLists:(NSArray *)sourceLists
{
    if (sourceLists == _sourceLists)
    {
        return;
    }
    
    // TODO - Send Remove Section/Object messages
    
    [_sourceLists makeObjectsPerformSelector:@selector(removeCollectionListObserver:) withObject:self];
    
    _sourceLists = [sourceLists copy];
    
    [self configureSectionsWithSourceLists:sourceLists];
    
    // TODO - Send Add Section/Object messages
    
    [sourceLists makeObjectsPerformSelector:@selector(addCollectionListObserver:) withObject:self];
}

#pragma mark - RZCollectionList

- (NSArray*)listObjects
{
    NSMutableArray *listObjects = [[NSMutableArray alloc] init];
    
    [self.sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<RZCollectionList> list = (id<RZCollectionList>)obj;
        [listObjects addObjectsFromArray:list.listObjects];
    }];
    
    return listObjects;
}

- (NSArray*)sections
{
    NSArray *sections = nil;
    
    if (self.ignoreSections)
    {
        sections = @[self.singleSectionInfo];
    }
    else
    {
        NSMutableArray *listSections = [[NSMutableArray alloc] init];
        [self.sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id<RZCollectionList> list = (id<RZCollectionList>)obj;
            [listSections addObjectsFromArray:list.sections];
        }];
        sections = listSections;
    }
    
    return sections;
}

- (NSArray*)cachedSections
{
    NSArray *sections = nil;
    if (self.ignoreSections)
    {
        sections = self.cachedSingleSectionInfo ? @[self.cachedSingleSectionInfo] : @[self.singleSectionInfo];
    }
    else if (nil != self.cachedSourceListSections)
    {
        NSMutableArray *cachedSections = [NSMutableArray array];
        [self.cachedSourceListSections enumerateObjectsUsingBlock:^(NSArray *sectionsArray, NSUInteger idx, BOOL *stop) {
            [cachedSections addObjectsFromArray:sectionsArray];
        }];
        sections = cachedSections;
    }
    else
    {
        sections = self.sections;
    }
    
    return sections;
}

- (NSArray*)sectionIndexTitles
{
    NSMutableArray *indexTitles = [NSMutableArray array];
    
    [self.sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *listTitles = [(id<RZCollectionList>)obj sectionIndexTitles];
        if (listTitles.count > 0)
        {
            [indexTitles addObjectsFromArray:listTitles];
        }
    }];
    
    return indexTitles;
}

- (id)objectAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.ignoreSections)
    {
        return [self.listObjects objectAtIndex:indexPath.row];
    }
    else
    {
        NSUInteger sourceListIndex = [[self.sourceListForSection objectAtIndex:indexPath.section] unsignedIntegerValue];
        NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:sourceListIndex] rangeValue];
        id<RZCollectionList> sourceList = [self.sourceLists objectAtIndex:sourceListIndex];
        
        NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - sourceListSectionRange.location];
        
        return [sourceList objectAtIndexPath:sourceIndexPath];
    }
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    __block NSIndexPath *indexPath = nil;
    
    if (self.ignoreSections)
    {
        NSArray *allObjects = self.listObjects;
        NSUInteger objectIndex = [allObjects indexOfObject:object];
        
        if (NSNotFound != objectIndex)
        {
            indexPath = [NSIndexPath indexPathForRow:objectIndex inSection:0];
        }
    }
    else
    {
        [self.sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id<RZCollectionList> list = (id<RZCollectionList>)obj;
            NSIndexPath *sourceIndexPath = [list indexPathForObject:object];
            
            if (nil != sourceIndexPath)
            {
                NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:idx] rangeValue];
                indexPath = [NSIndexPath indexPathForRow:sourceIndexPath.row inSection:sourceIndexPath.section + sourceListSectionRange.location];
                *stop = YES;
            }
        }];
    }
    
    return indexPath;
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
        id<RZCollectionListSectionInfo> section = [filteredArray lastObject];
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

#pragma mark - Update Helpers

- (void)beginPotentialUpdatesFromList:(id<RZCollectionList>)updatingList
{
    self.contentChangeState = RZCompositeSourceListContentChangeStatePotentialChanges;
    self.cachedSourceListSectionRanges = [[NSArray alloc] initWithArray:self.sourceListSectionRanges copyItems:YES];

    NSMutableArray *cachedSourceListSections = [NSMutableArray arrayWithCapacity:self.sourceLists.count];
    [self.sourceLists enumerateObjectsUsingBlock:^(id<RZCollectionList> sourceList, NSUInteger sourceListIdx, BOOL *stop) {
        
        // don't care about cached sections if the list isn't updating
        NSArray *sourceSections = (sourceList == updatingList) ? [sourceList cachedSections] : [sourceList sections];
        [cachedSourceListSections addObject:sourceSections];
        
    }];
    self.cachedSourceListSections = cachedSourceListSections;
    
    self.cachedSingleSectionInfo = [self.singleSectionInfo cachedCopy];
}

- (void)confirmPotentialUpdates
{
    if (self.contentChangeState == RZCompositeSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }

    self.contentChangeState = RZCompositeSourceListContentChangeStateChanged;
}

- (void)endPotentialUpdates
{
    [self processReceivedChangeNotifications];
    
    if (self.contentChangeState == RZCompositeSourceListContentChangeStateChanged)
    {
        [self sendAllPendingChangeNotifications];
        [self sendDidChangeContentNotifications];
    }
    
    self.contentChangeState = RZCompositeSourceListContentChangeStateNoChanges;
    [self resetPendingNotifications];
    self.cachedSourceListSectionRanges = nil;
    self.cachedSourceListSections = nil;
}


#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    // any object notification means we have updates, let's confirm them.
    [self confirmPotentialUpdates];
    [self cacheObjectNotificationWithObject:object indexPath:indexPath newIndexPath:newIndexPath type:type sourceList:collectionList];
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    // we don't care about section notifications if we are ignoring sections
    if (!self.ignoreSections)
    {
        [self confirmPotentialUpdates];
        [self cacheSectionNotificationWithSectionInfo:sectionInfo sectionIndex:sectionIndex type:type sourceList:collectionList];
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    [self beginPotentialUpdatesFromList:collectionList];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    [self endPotentialUpdates];
}

@end

@implementation RZCompositeCollectionListSectionInfo

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle compositeList:(RZCompositeCollectionList *)compositeList
{
    if ((self = [super init]))
    {
        self.name = name;
        self.indexTitle = indexTitle;
        self.compositeList = compositeList;
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

- (NSUInteger)numberOfObjects
{
    if (self.isCachedCopy)
    {
        return _numberOfObjects;
    }
    return self.compositeList.listObjects.count;
}

- (NSArray*)objects
{
    if (self.isCachedCopy)
    {
        return _objects;
    }
    return self.compositeList.listObjects;
}

- (id<RZCollectionListSectionInfo>)cachedCopy
{
    RZCompositeCollectionListSectionInfo *copy = [[RZCompositeCollectionListSectionInfo alloc] initWithName:[self.name copy]
                                                                                          sectionIndexTitle:[self.indexTitle copy]
                                                                                              compositeList:self.compositeList];
    
    copy.objects = self.objects;
    copy.numberOfObjects = self.numberOfObjects;
    copy.isCachedCopy = YES;
    return copy;
}

@end
