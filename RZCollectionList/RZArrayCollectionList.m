//
//  RZArrayCollectionList.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZArrayCollectionList.h"

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
        unsigned int _sendObjectChangeNotifications:1;
        unsigned int _sendSectionChangeNotifications:1;
        unsigned int _sendDidChangeContentNotifications:1;
        unsigned int _sendWillChangeContentNotifications:1;
        unsigned int _sendSectionIndexTitleForSectionName:1;
    } _flags;
}

@property (nonatomic, strong) NSMutableArray *sectionsInfo;
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, assign, getter = isBatchUpdating) BOOL batchUpdating;

+ (NSArray*)sectionsForObjects:(NSArray*)objects withNameKeyPath:(NSString*)keyPath;

- (void)updateSection:(RZArrayCollectionListSectionInfo*)section withObjectCountChange:(NSInteger)countChange;

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications;
- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications;
- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object sendNotifications:(BOOL)shouldSendNotifications;
- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath sendNotifications:(BOOL)shouldSendNotifications;

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications;
- (void)removeSectionAtIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications;

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
        self.objects = [array mutableCopy];
        self.sectionsInfo = [sections mutableCopy];
        
        [self.sectionsInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ((RZArrayCollectionListSectionInfo*)obj).arrayList = self;
        }];
    }
    
    return self;
}

- (void)setDelegate:(id<RZCollectionListDelegate>)delegate
{
    if (delegate == _delegate)
    {
        return;
    }
    
    _delegate = delegate;
    
    _flags._sendObjectChangeNotifications = [delegate respondsToSelector:@selector(collectionList:didChangeObject:atIndexPath:forChangeType:newIndexPath:)];
    _flags._sendSectionChangeNotifications = [delegate respondsToSelector:@selector(collectionList:didChangeSection:atIndex:forChangeType:)];
    _flags._sendDidChangeContentNotifications = [delegate respondsToSelector:@selector(collectionListDidChangeContent:)];
    _flags._sendWillChangeContentNotifications = [delegate respondsToSelector:@selector(collectionListWillChangeContent:)];
    _flags._sendSectionIndexTitleForSectionName = [delegate respondsToSelector:@selector(collectionList:sectionIndexTitleForSectionName:)];
}

#pragma mark - Mutators

- (void)addObject:(id)object toSection:(NSUInteger)section
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:section];
    
    [self insertObject:object atIndexPath:[NSIndexPath indexPathForRow:sectionInfo.numberOfObjects inSection:section]];
}

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self insertObject:object atIndexPath:indexPath sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)removeObject:(id)object
{
    NSIndexPath *indexPath = [self indexPathForObject:object];
    
    [self removeObjectAtIndexPath:indexPath];
}

- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self removeObjectAtIndexPath:indexPath sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self replaceObjectAtIndexPath:indexPath withObject:object sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self moveObjectAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)addSection:(RZArrayCollectionListSectionInfo*)section
{
    [self insertSection:section atIndex:self.sectionsInfo.count];
}

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self insertSection:section atIndex:index sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)removeSection:(RZArrayCollectionListSectionInfo*)section
{
    NSUInteger index = [self.sectionsInfo indexOfObject:section];
    
    [self removeSectionAtIndex:index];
}

- (void)removeSectionAtIndex:(NSUInteger)index
{
    if (!self.batchUpdating && _flags._sendWillChangeContentNotifications)
    {
        [self.delegate collectionListWillChangeContent:self];
    }
    
    [self removeSectionAtIndex:index sendNotifications:YES];
    
    if (!self.batchUpdating && _flags._sendDidChangeContentNotifications)
    {
        [self.delegate collectionListDidChangeContent:self];
    }
}

- (void)beginUpdates
{
    if(!self.batchUpdating)
    {
        self.batchUpdating = YES;
        if (_flags._sendWillChangeContentNotifications)
        {
            [self.delegate collectionListWillChangeContent:self];
        }
    }
}

- (void)endUpdates
{
    if (self.batchUpdating)
    {
        if (_flags._sendDidChangeContentNotifications)
        {
            [self.delegate collectionListDidChangeContent:self];
        }
        
        self.batchUpdating = NO;
    }
}

#pragma mark - Internal Mutators

- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
    NSUInteger index = sectionInfo.indexOffset + indexPath.row;
    
    [self.objects insertObject:object atIndex:index];
    
    [self updateSection:sectionInfo withObjectCountChange:1];
    
    if (shouldSendNotifications && _flags._sendObjectChangeNotifications)
    {
        [self.delegate collectionList:self didChangeObject:object atIndexPath:nil forChangeType:RZCollectionListChangeInsert newIndexPath:indexPath];
    }
}

- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
    NSUInteger index = sectionInfo.indexOffset + indexPath.row;
    
    id object = [self.objects objectAtIndex:index];
    
    [self.objects removeObjectAtIndex:index];
    
    [self updateSection:sectionInfo withObjectCountChange:-1];
    
    if (sectionInfo.numberOfObjects == 0)
    {
        [self removeSectionAtIndex:indexPath.section sendNotifications:shouldSendNotifications];
    }
    
    if (shouldSendNotifications && _flags._sendObjectChangeNotifications)
    {
        [self.delegate collectionList:self didChangeObject:object atIndexPath:indexPath forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
    }
}

- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:indexPath.section];
    NSUInteger index = sectionInfo.indexOffset + indexPath.row;
    
    [self.objects replaceObjectAtIndex:index withObject:object];
    
    if (shouldSendNotifications && _flags._sendObjectChangeNotifications)
    {
        [self.delegate collectionList:self didChangeObject:object atIndexPath:indexPath forChangeType:RZCollectionListChangeUpdate newIndexPath:nil];
    }
}

- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath sendNotifications:(BOOL)shouldSendNotifications
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
    
    [self insertObject:object atIndexPath:destIndexPath sendNotifications:NO];
    [self removeObjectAtIndexPath:removeIndexPath sendNotifications:NO];
    
    if (shouldSendNotifications && _flags._sendObjectChangeNotifications)
    {
        [self.delegate collectionList:self didChangeObject:object atIndexPath:sourceIndexPath forChangeType:RZCollectionListChangeMove newIndexPath:destinationIndexPath];
    }
    
}

- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications
{
    [self.sectionsInfo insertObject:section atIndex:index];
    section.arrayList = self;
    
    if (shouldSendNotifications && _flags._sendSectionChangeNotifications)
    {
        [self.delegate collectionList:self didChangeSection:section atIndex:index forChangeType:RZCollectionListChangeInsert];
    }
}

- (void)removeSectionAtIndex:(NSUInteger)index sendNotifications:(BOOL)shouldSendNotifications
{
    RZArrayCollectionListSectionInfo *sectionInfo = [self.sectionsInfo objectAtIndex:index];
    
    if (sectionInfo.numberOfObjects > 0)
    {
        NSArray *objectsToRemove = [self.objects subarrayWithRange:sectionInfo.range];
        
        [self.objects removeObjectsInRange:sectionInfo.range];
        
        [self updateSection:sectionInfo withObjectCountChange:-objectsToRemove.count];
        
        [objectsToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (shouldSendNotifications && _flags._sendObjectChangeNotifications)
            {
                [self.delegate collectionList:self didChangeObject:obj atIndexPath:[NSIndexPath indexPathForRow:idx inSection:sectionInfo.indexOffset] forChangeType:RZCollectionListChangeDelete newIndexPath:nil];
            }
        }];
    }
    
    [self.sectionsInfo removeObjectAtIndex:index];
    sectionInfo.arrayList = nil;
    
    if (shouldSendNotifications && _flags._sendSectionChangeNotifications)
    {
        [self.delegate collectionList:self didChangeSection:sectionInfo atIndex:index forChangeType:RZCollectionListChangeDelete];
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
                    [sectionsInfo addObject:currentSection];
                }
                
                RZArrayCollectionListSectionInfo *nextSection = [[RZArrayCollectionListSectionInfo alloc] initWithName:sectionName sectionIndexTitle:nil numberOfObjects:0];
                nextSection.indexOffset = idx;
                
                currentSection = nextSection;
            }
            
        }];
        
        currentSection.numberOfObjects = [objects count] - currentSection.indexOffset;
        [sectionsInfo addObject:currentSection];
        
        sections = sectionsInfo;
    }
    
    return sections;
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
    RZArrayCollectionListSectionInfo *section = [self.sectionsInfo objectAtIndex:indexPath.section];
    
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
            rowIndex = idx - section.indexOffset;
            *stop = YES;
        }
        
        return inRange;
    }];
    
    return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
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
        RZArrayCollectionListSectionInfo *section = [self.sectionsInfo objectAtIndex:sectionIndex];
        
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

@end