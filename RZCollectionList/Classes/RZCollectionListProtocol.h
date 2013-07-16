//
//  RZCollectionListProtocol.h
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

//! Return a copy of this object which returns STATIC values for all properties above
/*!
    This is different from NSCopying in the sense that a cachedCopy of section info
    should not derive its property values from a dynamic source (source list, etc)
    but rather should return a static value for each property.
*/
- (id<RZCollectionListSectionInfo>)cachedCopy;

@end

@protocol RZCollectionListDelegate;
@protocol RZCollectionListObserver;

@protocol RZCollectionList <NSObject>

@required

@property (nonatomic, readonly) NSArray *listObjects;
@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, readonly) NSArray *cachedSections; // sections cached prior to update, cleared when update is finished
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
    RZCollectionListChangeInvalid = -1,
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



