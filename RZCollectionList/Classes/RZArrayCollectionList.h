//
//  RZArrayCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListProtocol.h"
#import "RZBaseCollectionList.h"

@interface RZArrayCollectionListSectionInfo : NSObject <RZCollectionListSectionInfo>

@property (nonatomic, assign) NSUInteger indexOffset;

- (instancetype)initWithName:(NSString*)name sectionIndexTitle:(NSString*)indexTitle numberOfObjects:(NSUInteger)numberOfObjects;

@end

/**
 *  A source collection list based on an in-memory array of objects, with optional sectioning.
 *
 *  @warning Currently, each object in the array list must be unique, meaning isEqual: returns NO when comparing two objects.
 */
@interface RZArrayCollectionList : RZBaseCollectionList

@property (nonatomic, copy) NSArray *objectUpdateNotifications;

/**
 *  Automatically infer sections based on keypath
 *
 *  @param array   Initial array.
 *  @param keyPath keyPath for which we can infer the sections from the objects in the array.
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied array and organized into sections based on the supplied keypath
 */
- (instancetype)initWithArray:(NSArray*)array sectionNameKeyPath:(NSString*)keyPath;

/**
 *  Manually create sections for objects in array
 *
 *  @param array    Initial array.
 *  @param sections Section info for the array. All objects must be of type RZArrayCollectionListSectionInfo
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied sections and array
 */
- (instancetype)initWithArray:(NSArray*)array sections:(NSArray*)sections;

/**
 *  Create multiple sections, each with a title and array of objects
 *  Order of variadic args should be title (NSString), objects (NSArray)
 *  
 *  @param firstSectionTitle The title of the first section.
 *
 *  @return An instance of RZArrayCollectionList populated with the supplied sections
 */
- (instancetype)initWithSectionTitlesAndSectionArrays:(NSString*)firstSectionTitle, ... NS_REQUIRES_NIL_TERMINATION;

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
 *  Remove all objects in the list.
 */
- (void)removeAllObjects;

/**
 *  Adds a section with the specified info.
 *
 *  @param section The section info for the section to add. Must not be nil.
 */
- (void)addSection:(RZArrayCollectionListSectionInfo *)section;

/**
 *  Insert a section at a specific index.
 *
 *  @param section The section to insert.
 *  @param index   The index at which to insert the section.
 */
- (void)insertSection:(RZArrayCollectionListSectionInfo*)section atIndex:(NSUInteger)index;

/**
 *  Remove a section.
 *
 *  @param section The section info of the section to remove.
 */
- (void)removeSection:(RZArrayCollectionListSectionInfo *)section;

/**
 *  Remove a section at a specific index.
 *
 *  @param index The index at which to remove the section.
 */
- (void)removeSectionAtIndex:(NSUInteger)index;

/**
 *  Begin a batch update to the array list.
 *
 *  @warning Must be matched by a call to endUpdates.
 */
- (void)beginUpdates;

/**
 *  End a batch update to the array list and deliver all observer notifications.
 */
- (void)endUpdates;

@end
