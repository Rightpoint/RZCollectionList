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

/**
 *  @warning CURRENTLY ASSUMING EACH OBJECT IN ARRAY IS UNIQUE INSTANCE
 */
@interface RZArrayCollectionList : RZBaseCollectionList <RZCollectionList>

@property (nonatomic, copy) NSArray *objectUpdateNotifications;

/**
 *  Automatically infer sections based on keypath
 *
 *  @param array   input array
 *  @param keyPath keyPath for which we can infer the title from the object
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied array and organized into sections based on the supplied keypath
 */
- (id)initWithArray:(NSArray*)array sectionNameKeyPath:(NSString*)keyPath;

/**
 *  Manually create sections for objects in array
 *
 *  @param array    input array
 *  @param sections all objects must be of type RZArrayCollectionListSectionInfo
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied sections and array
 */
- (id)initWithArray:(NSArray*)array sections:(NSArray*)sections;

/**
 *  Create multiple sections, each with a title and array of objects
 *  Order of variadic args should be title (NSString), objects (NSArray)
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied sections
 */
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

/**
 *  Call before all of your batch update logic
 */
- (void)beginUpdates;
/**
 *  Call after all of your batch update logic
 */
- (void)endUpdates;

@end
