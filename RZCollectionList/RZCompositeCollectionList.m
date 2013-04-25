//
//  RZCompositeCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCompositeCollectionList.h"
#import "RZObserverCollection.h"

@interface RZCompositeCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *indexTitle;

@property (nonatomic, weak) RZCompositeCollectionList *compositeList;

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle compositeList:(RZCompositeCollectionList*)compositeList;

@end

typedef enum {
    RZCompositeSourceListContentChangeStateNoChanges,
    RZCompositeSourceListContentChangeStatePotentialChanges,
    RZCompositeSourceListContentChangeStateChanged
} RZCompositeSourceListContentChangeState;

@interface RZCompositeCollectionList ()

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;
@property (nonatomic, strong) NSMutableArray *sourceListSectionRanges;
@property (nonatomic, strong) NSMutableArray *sourceListForSection;

@property (nonatomic, assign) BOOL ignoreSections;
@property (nonatomic, strong) RZCompositeCollectionListSectionInfo *singleSectionInfo;

@property (nonatomic, assign) RZCompositeSourceListContentChangeState contentChangeState;

- (void)configureSectionsWithSourceLists:(NSArray*)sourceLists;

// Section Helpers
- (void)addSectionForSourceList:(id<RZCollectionList>)sourceList;
- (void)removeSectionForSourceList:(id<RZCollectionList>)sourceList;

// Update Helpers
- (void)beginPotentialUpdates;
- (void)endPotentialUpdates;

// Notification helpers
- (void)sendWillChangeContentNotifications;
- (void)sendDidChangeContentNotifications;
- (void)sendDidChangeObjectNotification:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;
- (void)sendDidChangeSectionNotification:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex  forChangeType:(RZCollectionListChangeType)type;

@end

@implementation RZCompositeCollectionList
@synthesize delegate = _delegate;

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
    [self.sourceListSectionRanges enumerateObjectsAtIndexes:rangesToModify options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSValue *newRangeValue = [NSValue valueWithRange:NSMakeRange(range.location+1, range.length)];
        [self.sourceListSectionRanges replaceObjectAtIndex:idx withObject:newRangeValue];
    }];
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
    [self.sourceListSectionRanges enumerateObjectsAtIndexes:rangesToModify options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSRange range = [obj rangeValue];
        NSValue *newRangeValue = [NSValue valueWithRange:NSMakeRange(range.location-1, range.length)];
        [self.sourceListSectionRanges replaceObjectAtIndex:idx withObject:newRangeValue];
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

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

#pragma mark - Update Helpers

- (void)beginPotentialUpdates
{
    self.contentChangeState = RZCompositeSourceListContentChangeStatePotentialChanges;
}

- (void)endPotentialUpdates
{
    if (self.contentChangeState == RZCompositeSourceListContentChangeStateChanged)
    {
        [self sendDidChangeContentNotifications];
    }
    
    self.contentChangeState = RZCompositeSourceListContentChangeStateNoChanges;
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
    if (self.contentChangeState == RZCompositeSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }
    
    self.contentChangeState = RZCompositeSourceListContentChangeStateChanged;
    
    if (self.ignoreSections)
    {
        NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:collectionList];
        
        __block NSUInteger rowOffset = 0;
        
        [self.sourceLists enumerateObjectsUsingBlock:^(id<RZCollectionList> sourceList, NSUInteger listIdx, BOOL *listStop) {
            if (listIdx == indexOfSourceList)
            {
                [sourceList.sections enumerateObjectsUsingBlock:^(id<RZCollectionListSectionInfo> section, NSUInteger sectionIdx, BOOL *sectionStop) {
                    if (sectionIdx == indexPath.section)
                    {
                        *sectionStop = YES;
                    }
                    else
                    {
                        rowOffset += section.numberOfObjects;
                    }
                }];
                *listStop = YES;
            }
            else
            {
                rowOffset += sourceList.listObjects.count;
            }
        }];
        
        NSIndexPath *modifiedIndexPath = (indexPath == nil) ? nil : [NSIndexPath indexPathForRow:indexPath.row + rowOffset inSection:0];
        NSIndexPath *modifiedNewIndexPath = (newIndexPath == nil) ? nil : [NSIndexPath indexPathForRow:newIndexPath.row + rowOffset inSection:0];
        
        [self sendDidChangeObjectNotification:object atIndexPath:modifiedIndexPath forChangeType:type newIndexPath:modifiedNewIndexPath];
    }
    else
    {
        NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:collectionList];
        NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        NSIndexPath *modifiedIndexPath = (indexPath == nil) ? nil : [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section + sourceListSectionRange.location];
        NSIndexPath *modifiedNewIndexPath = (newIndexPath == nil) ? nil : [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section + sourceListSectionRange.location];
        
        [self sendDidChangeObjectNotification:object atIndexPath:modifiedIndexPath forChangeType:type newIndexPath:modifiedNewIndexPath];
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    if (!self.ignoreSections)
    {
        if (self.contentChangeState == RZCompositeSourceListContentChangeStatePotentialChanges)
        {
            [self sendWillChangeContentNotifications];
        }
        
        self.contentChangeState = RZCompositeSourceListContentChangeStateChanged;
        
        NSUInteger indexOfSourceList = [self.sourceLists indexOfObject:collectionList];
        NSRange sourceListSectionRange = [[self.sourceListSectionRanges objectAtIndex:indexOfSourceList] rangeValue];
        NSUInteger modifiedSectionIndex = sectionIndex + sourceListSectionRange.location;
        
        [self sendDidChangeSectionNotification:sectionInfo atIndex:modifiedSectionIndex forChangeType:type];
        
        switch(type) {
            case RZCollectionListChangeInsert:
                [self addSectionForSourceList:collectionList];
                break;
            case RZCollectionListChangeDelete:
                [self removeSectionForSourceList:collectionList];
                break;
            default:
                //uncaught type
                NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
                break;
        }
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
    return self.compositeList.listObjects.count;
}

- (NSArray*)objects
{
    return self.compositeList.listObjects;
}

@end
