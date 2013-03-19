//
//  RZCollectionListUIKitDataSourceAdapter.m
//  bhphoto
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListUIKitDataSourceAdapter.h"
#import "RZObserverCollection.h"

@interface RZCollectionListUIKitDataSourceAdapter ()

@property (nonatomic, strong) RZObserverCollection *observerCollection;
@property (nonatomic, strong) NSMutableArray *removedIndexPaths;
@property (nonatomic, strong) NSMutableArray *addedIndexPaths;
@property (nonatomic, assign) BOOL isUpdating;

- (void)commonInit;

@end

@implementation RZCollectionListUIKitDataSourceAdapter

- (id)init{
    self = [super init];
    if (self){
        [self commonInit];
    }
    return self;
}

- (id)initWithObserver:(id<RZCollectionListObserver>)observer
{
    self = [super init];
    if (self) {
        [self commonInit];
        [self.observerCollection addObject:observer];
    }
    return self;
}

- (void)commonInit
{
    self.observerCollection = [[RZObserverCollection alloc] init];
    self.addedIndexPaths = [NSMutableArray arrayWithCapacity:64];
    self.removedIndexPaths = [NSMutableArray arrayWithCapacity:64];
}

- (void)addObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection addObject:observer];
}

- (void)removeObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection removeObject:observer];
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSIndexPath *swizzledIndexPath = indexPath;
    NSIndexPath *swizzledNewIndexPath = newIndexPath;
    
    

    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionList:collectionList didChangeObject:object atIndexPath:swizzledIndexPath forChangeType:type newIndexPath:swizzledNewIndexPath];
    }];
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    NSUInteger swizzledSectionIndex = sectionIndex;
    
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionList:collectionList didChangeSection:sectionInfo atIndex:swizzledSectionIndex forChangeType:type];
    }];
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    self.isUpdating = YES;
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListWillChangeContent:collectionList];
    }];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.isUpdating){
        [self.addedIndexPaths removeAllObjects];
        [self.removedIndexPaths removeAllObjects];
        self.isUpdating = NO;
    }
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListWillChangeContent:collectionList];
    }];
}

@end
