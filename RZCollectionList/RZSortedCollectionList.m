//
//  RZSortedCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZSortedCollectionList.h"
#import "RZObserverCollection.h"

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

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

@property (nonatomic, assign) RZSortedSourceListContentChangeState contentChangeState;

- (NSArray*)sortedSections;

// Mutation helpers
- (void)addSourceObject:(id)object;
- (void)removeSourceObject:(id)object;
- (void)updateSourceObject:(id)object;

- (void)beginPotentialUpdates;
- (void)endPotentialUpdates;

// Notification helpers
- (void)sendWillChangeContentNotifications;
- (void)sendDidChangeContentNotifications;
- (void)sendDidChangeObjectNotification:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;
- (void)sendDidChangeSectionNotification:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex  forChangeType:(RZCollectionListChangeType)type;

@end

@implementation RZSortedCollectionList
@synthesize delegate = _delegate;

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
        
        [self.sortedListObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self removeSourceObject:obj];
        }];
        
        [self sendDidChangeContentNotifications];
        
        _sortDescriptors = [sortDescriptors copy];
        
        NSArray *sortedObjects = [self.sourceList.listObjects sortedArrayUsingDescriptors:sortDescriptors];
        
        [self sendWillChangeContentNotifications];
        
        [sortedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self addSourceObject:obj];
        }];
        
        [self sendDidChangeContentNotifications];
        
        self.sortedListObjects = [sortedObjects mutableCopy];
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

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers addObject:listObserver];
}

- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver
{
    [self.collectionListObservers removeObject:listObserver];
}

#pragma mark - Mutation Helpers

- (void)addSourceObject:(id)object
{
    if (self.contentChangeState == RZSortedSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }
    
    self.contentChangeState = RZSortedSourceListContentChangeStateChanged;
    
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
    
    [self sendDidChangeObjectNotification:object atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:[NSIndexPath indexPathForRow:insertIndex inSection:0]];
}

- (void)removeSourceObject:(id)object
{
    if (self.contentChangeState == RZSortedSourceListContentChangeStatePotentialChanges)
    {
        [self sendWillChangeContentNotifications];
    }
    
    self.contentChangeState = RZSortedSourceListContentChangeStateChanged;
    
    NSUInteger objectIndex = [self.sortedListObjects indexOfObject:object];
    
    NSIndexPath *sortedIndexPath = [NSIndexPath indexPathForRow:objectIndex inSection:0];
    
    [self.sortedListObjects removeObjectAtIndex:objectIndex];
    
    [self sendDidChangeObjectNotification:object atIndexPath:sortedIndexPath forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
    
//    if ([sectionIndexSet count] == 0 && [self.sectionIndexes containsIndex:indexPath.section])
//    {
//        NSUInteger filteredSection = [self filteredSectionIndexForSourceSectionIndex:indexPath.section];
//        RZSortedCollectionListSectionInfo *filteredSectionInfo = [[self filteredCachedSections] objectAtIndex:filteredSection];
//        
//        [self sendDidChangeSectionNotification:filteredSectionInfo atIndex:filteredSection forChangeType:RZCollectionListChangeDelete];
//        
//        [self.sectionIndexes removeIndex:indexPath.section];
//    }
}

- (void)updateSourceObject:(id)object
{
    NSIndexPath *indexPath = [self indexPathForObject:object];
    [self sendDidChangeObjectNotification:object atIndexPath:indexPath forChangeType:RZCollectionListChangeUpdate newIndexPath:nil];
}

- (void)beginPotentialUpdates
{
    self.contentChangeState = RZSortedSourceListContentChangeStatePotentialChanges;
//    self.cachedSourceSections = [self.sourceList.sections copy];
}

- (void)endPotentialUpdates
{
    if (self.contentChangeState == RZSortedSourceListContentChangeStateChanged)
    {
        [self sendDidChangeContentNotifications];
    }
    
    self.contentChangeState = RZSortedSourceListContentChangeStateNoChanges;
//    self.cachedSourceSections = nil;
}

#pragma mark - Notification Helpers

- (void)sendWillChangeContentNotifications
{
#if kRZCollectionListNotificationsLogging
    NSLog(@"RZSortedCollectionList Will Change");
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
    NSLog(@"RZSortedCollectionList Did Change");
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
    NSLog(@"RZSortedCollectionList Did Change Object: %@ IndexPath:%@ Type: %d NewIndexPath: %@", object, indexPath, type, newIndexPath);
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
    NSLog(@"RZSortedCollectionList Did Change Section: %@ Index:%d Type: %d", sectionInfo, sectionIndex, type);
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
            [self addSourceObject:object];
            break;
        case RZCollectionListChangeDelete:
            [self removeSourceObject:object];
            break;
        case RZCollectionListChangeMove:
            break;
        case RZCollectionListChangeUpdate:
            [self updateSourceObject:object];
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
            break;
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

@end
