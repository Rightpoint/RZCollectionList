//
//  RZArrayCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionList.h"

@interface RZArrayCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo, NSCopying>

@property (nonatomic, assign) NSUInteger indexOffset;

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle numberOfObjects:(NSUInteger)numberOfObjects;

@end

@interface RZArrayCollectionList : RZBaseCollectionList <RZCollectionList>

@property (nonatomic, copy) NSArray *objectUpdateNotifications;

- (id)initWithArray:(NSArray*)array sections:(NSArray*)sections;
- (id)initWithArray:(NSArray*)array sectionNameKeyPath:(NSString*)keyPath;

/**** CURRENTLY ASSUMING EACH OBJECT IN ARRAY IS UNIQUE INSTANCE *****/

- (void)addObject:(id)object toSection:(NSUInteger)section;
- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath;
- (void)removeObject:(id)object;
- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath;
- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object;
- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath;
- (void)removeAllObjects;

- (void)addSection:(RZArrayCollectionListSectionInfo*)section;
- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index;
- (void)removeSection:(RZArrayCollectionListSectionInfo*)section;
- (void)removeSectionAtIndex:(NSUInteger)index;

- (void)beginUpdates;
- (void)endUpdates;

@end
