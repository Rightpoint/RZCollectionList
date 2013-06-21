//
//  RZCollectionList.h
//  RZCollectionList
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kRZCollectionListNotificationsLogging 0

@protocol RZCollectionListSectionInfo <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *indexTitle;
@property (nonatomic, assign, readonly) NSUInteger numberOfObjects;
@property (nonatomic, readonly) NSArray *objects;

@end

@protocol RZCollectionListDelegate;
@protocol RZCollectionListObserver;

@protocol RZCollectionList <NSObject>

@property (nonatomic, readonly) NSArray *listObjects;
@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, readonly) NSArray *listObservers;
@property (nonatomic, weak) id<RZCollectionListDelegate> delegate;

@property (nonatomic, readonly) NSArray *sectionIndexTitles;


- (id)objectAtIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)indexPathForObject:(id)object;

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex;

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver;
- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

@end


@protocol RZCollectionListObserver <NSObject>

typedef enum {
    RZCollectionListChangeInsert = 1,
    RZCollectionListChangeDelete = 2,
    RZCollectionListChangeMove = 3,
    RZCollectionListChangeUpdate = 4
} RZCollectionListChangeType;

@required
- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type;

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList;

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList;

@end

@protocol RZCollectionListDelegate <NSObject>

@optional
- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName;

@end


/**************************************************
 *
 * Base class for providing common variables and
 * utils for RZCollectionList adopters.
 *
 * This class does not implement the protocol itself.
 *
 **************************************************/

@interface RZBaseCollectionList : NSObject

// batch update object cache containers

// these should be used to cache contents of the current collection or
// an observed collection prior to mutating the internal state
@property (nonatomic, strong) NSArray *sectionsInfoBeforeUpdateDeep;       // deep-copies - range/offset will not change during update
@property (nonatomic, strong) NSArray *sectionsInfoBeforeUpdateShallow;    // shallow-copies - use only for index lookup after update
@property (nonatomic, strong) NSArray *objectsBeforeUpdate;

// these should be used to cache section/object changes during an update
@property (nonatomic, strong) NSMutableSet *sectionsInsertedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *sectionsRemovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsInsertedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsRemovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsMovedDuringUpdate;
@property (nonatomic, strong) NSMutableSet *objectsUpdatedDuringUpdate;

- (void)clearCachedCollectionInfo;

@end
