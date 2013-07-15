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

@interface RZCompositeCollectionList ()

@property (nonatomic, strong) NSMutableArray *sourceListSectionRanges;
@property (nonatomic, strong) NSMutableArray *sourceListForSection;

@property (nonatomic, strong) NSArray *cachedSourceListSectionRanges;

- (void)configureSectionsWithSourceLists:(NSArray*)sourceLists;

// Section Helpers
- (void)addSectionForSourceList:(id<RZCollectionList>)sourceList;
- (void)removeSectionForSourceList:(id<RZCollectionList>)sourceList;

- (void)translateObjectNotification:(RZCollectionListObjectNotification*)notification;
- (void)translateSectionNotification:(RZCollectionListSectionNotification*)notification;

- (void)processReceivedChangeNotifications;

@end

@implementation RZCompositeCollectionList

- (id)initWithSourceLists:(NSArray*)sourceLists
{
    if ((self = [super init]))
    {
        self.sourceLists = sourceLists;
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
    NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:notification.sourceList];
    
    NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
    NSRange sourceListSectionRangeCached = [[self.cachedSourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
    
    NSIndexPath *modifiedIndexPath = (notification.indexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.indexPath.row inSection:notification.indexPath.section + sourceListSectionRangeCached.location];
    NSIndexPath *modifiedNewIndexPath = (notification.nuIndexPath == nil) ? nil : [NSIndexPath indexPathForRow:notification.nuIndexPath.row inSection:notification.nuIndexPath.section + sourceListSectionRange.location];
    
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
    NSMutableArray *listSections = [[NSMutableArray alloc] init];
    
    [self.sourceLists enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<RZCollectionList> list = (id<RZCollectionList>)obj;
        [listSections addObjectsFromArray:list.sections];
    }];
    
    return listSections;
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
    NSUInteger sourceListIndex = [[self.sourceListForSection objectAtIndex:indexPath.section] unsignedIntegerValue];
    NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:sourceListIndex] rangeValue];
    id<RZCollectionList> sourceList = [self.sourceLists objectAtIndex:sourceListIndex];
    
    NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - sourceListSectionRange.location];
    
    return [sourceList objectAtIndexPath:sourceIndexPath];
}

- (NSIndexPath*)indexPathForObject:(id)object
{
    __block NSIndexPath *indexPath = nil;
    
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

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    [self cacheObjectNotificationWithObject:object indexPath:indexPath newIndexPath:newIndexPath type:type sourceList:collectionList];
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    [self cacheSectionNotificationWithSectionInfo:sectionInfo sectionIndex:sectionIndex type:type sourceList:collectionList];
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    self.cachedSourceListSectionRanges = [[NSArray alloc] initWithArray:self.sourceListSectionRanges copyItems:YES];
    
    [self sendWillChangeContentNotifications];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    [self processReceivedChangeNotifications];
    [self sendAllPendingChangeNotifications];
    [self sendDidChangeContentNotifications];
    [self resetPendingNotifications];
    self.cachedSourceListSectionRanges = nil;
}

@end
