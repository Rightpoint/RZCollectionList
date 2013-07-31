//
//  RZArrayCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"
#import "RZBaseCollectionList.h"

@interface RZArrayCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, assign) NSUInteger indexOffset;

- (id)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle numberOfObjects:(NSUInteger)numberOfObjects;

@end

/**** CURRENTLY ASSUMING EACH OBJECT IN ARRAY IS UNIQUE INSTANCE *****/

@interface RZArrayCollectionList : RZBaseCollectionList <RZCollectionList>

@property (nonatomic, copy) NSArray *objectUpdateNotifications;

// Automatically infer sections based on keypath
- (id)initWithArray:(NSArray*)array sectionNameKeyPath:(NSString*)keyPath;

// Manually create sections for objects in array
- (id)initWithArray:(NSArray*)array sections:(NSArray*)sections;

// Create multiple sections, each with a title and array of objects
// Order of variadic args should be title (NSSTring), objects (NSArray)
- (id)initWithSectionTitlesAndSectionArrays:(NSString*)firstSectionTitle, ... NS_REQUIRES_NIL_TERMINATION;


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
