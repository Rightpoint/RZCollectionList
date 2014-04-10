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

/**
 *  Add an object to a particular section.
 *
 *  @param object  The object to add.
 *  @param section The section in which to place the object.
 */
- (void)addObject:(id)object toSection:(NSUInteger)section;

/**
 *  Insert an object at a specific index path
 *
 *  @param object    The object to insert.
 *  @param indexPath The index path at which the desired object for insertion lies.
 */
- (void)insertObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 *  Remove an object.
 *
 *  @param object The object to remove.
 */
- (void)removeObject:(id)object;

/**
 *  Remove an object at a specific index path.
 *
 *  @param indexPath The index path at which the desired object for removal lies.
 */
- (void)removeObjectAtIndexPath:(NSIndexPath*)indexPath;

/**
 *  Replace an existing object with a new object.
 *
 *  @param indexPath The index path of the existing object.
 *  @param object    The new object to replace the existing object.
 */
- (void)replaceObjectAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object;

/**
 *  Move an existing object to a new index path.
 *
 *  @param sourceIndexPath      The current index path of the object to move.
 *  @param destinationIndexPath The destination index path of the object to move.
 */
- (void)moveObjectAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath;

/**
 *  Remove all objects in an id<RZcollectionList> instance.
 */
- (void)removeAllObjects;

/**
 *  Adds a section to an id<RZcollectionList> instance.
 *
 *  @param section The section to add.
 */
- (void)addSection:(RZArrayCollectionListSectionInfo*)section;

/**
 *  Insert a section at a specific index.
 *
 *  @param section The section to insert.
 *  @param index   The index at which to insert the section.
 */
- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index;

/**
 *  Remove a section from an id<RZcollectionList> instance.
 *
 *  @param section The section to remove.
 */
- (void)removeSection:(RZArrayCollectionListSectionInfo*)section;

/**
 *  Remove a section at a specific index.
 *
 *  @param index The index at which to remove the section.
 */
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
