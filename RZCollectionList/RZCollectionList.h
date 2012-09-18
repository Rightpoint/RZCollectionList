//
//  RZCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RZCollectionListSectionInfo <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *indexTitle;
@property (nonatomic, assign, readonly) NSUInteger numberOfObjects;
@property (nonatomic, readonly) NSArray *objects;

@end

@protocol RZCollectionListDelegate;

@protocol RZCollectionList <NSObject>

@property (nonatomic, readonly) NSArray *listObjects;
@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, weak) id<RZCollectionListDelegate> delegate;

@property (nonatomic, readonly) NSArray *sectionIndexTitles;


- (id)objectAtIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)indexPathForObject:(id)object;

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex;

@end


@protocol RZCollectionListDelegate <NSObject>

typedef enum {
    RZCollectionListChangeInsert = 1,
    RZCollectionListChangeDelete = 2,
    RZCollectionListChangeMove = 3,
    RZCollectionListChangeUpdate = 4
} RZCollectionListChangeType;

@optional
- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type;

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList;

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList;

- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName;

@end