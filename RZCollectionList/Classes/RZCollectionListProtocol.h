//
//  RZCollectionListProtocol.h
//  RZCollectionList
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kRZCollectionListNotificationsLogging 0

/**
 *  Protocol to be implemented by an object representing section info within a source list.
 */
@protocol RZCollectionListSectionInfo <NSObject>

/**
 *  The full name of the section.
 */
@property (nonatomic, readonly) NSString *name;
/**
 *  The index title of the section. Often what is shown in the index sidebar of a UITableView.
 */
@property (nonatomic, readonly) NSString *indexTitle;
/**
 *  The total number of objects in this section.
 */
@property (nonatomic, assign, readonly) NSUInteger numberOfObjects;
/**
 *  The list of objects in this section.
 */
@property (nonatomic, readonly) NSArray *objects;

/** Return a copy of this object which returns STATIC values for all properties above
 *  This is different from NSCopying in the sense that a cachedCopy of section info
 *  should not derive its property values from a dynamic source (source list, etc)
 *  but rather should return a static value for each property.
 */
- (id<RZCollectionListSectionInfo>)cachedCopy;

@end

@protocol RZCollectionListDelegate;
@protocol RZCollectionListObserver;

/**
 *  Protocol defining a collection list.
 *  Any object conforming to this protocol may be used as a collection list.
 */
@protocol RZCollectionList <NSObject>

@required

/**
 *  All objects in the collection list in a flat array.
 */
@property (nonatomic, readonly) NSArray *listObjects;

/**
 *  An array of RZArrayCollectionListSectionInfo
 */
@property (nonatomic, readonly) NSArray *sections;

/**
 *  Sections cached prior to update, cleared when update is finished
 */
@property (nonatomic, readonly) NSArray *cachedSections;

/**
 *  A list of all entities who subscribe to the RZCollectionListObserver protocol for this RZCollectionList instance
 */
@property (nonatomic, readonly) NSArray *listObservers;

/**
 *  Optional delegate for providing section index title.
 */
@property (nonatomic, weak) id<RZCollectionListDelegate> delegate;

/**
 *  Titles for all sections of this RZCollectionList instance.
 *  Should have the same number of objects as @p sections.
 */
@property (nonatomic, readonly) NSArray *sectionIndexTitles;

/**
 *  Retrieve the object at the designated index path of a collection list.
 *
 *  @param indexPath The index path of the desired object.
 *
 *  @return The object at the designated index path, if it exists, otherwise nil.
 */
- (id)objectAtIndexPath:(NSIndexPath*)indexPath;

/**
 *  Retrieve the index path of an object in a collection list.
 *
 *  @param object The object in the collection list for which you require an index path.
 *
 *  @return An NSIndexPath of the parameter object if the object exists in the collection list, otherwise nil.
 */
- (NSIndexPath*)indexPathForObject:(id)object;

/**
 *  Retrieve the index title for a section.
 *
 *  @param sectionName The section name used to identify the section.
 *
 *  @return The index title, if it exists, or nil.
 */
- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

/**
 *  Tell the collection list which section corresponds to section title/index (e.g. "B",1))
 *
 *  @param title        The index title for the section.
 *  @param sectionIndex The index of the section.
 *
 *  @return The index of the section in the collection list.
 */
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex;

/**
 *  Add an observer to the list of observers for this collection list.
 *
 *  @param listObserver An object that conforms to the RZCollectionListObserver protocol.
 */
- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

/**
 *  Remove an observer from the list of observers fro this collection list.
 *
 *  @param listObserver An object that conforms to the RZCollectionListObserver protocol.
 */
- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

@end

/**
 *  All of the types of changes for update notifications.
 */
typedef NS_ENUM(NSInteger, RZCollectionListChangeType ) {
    RZCollectionListChangeInvalid = -1,
    RZCollectionListChangeInsert = 1,
    RZCollectionListChangeDelete = 2,
    RZCollectionListChangeMove = 3,
    RZCollectionListChangeUpdate = 4
};

/**
 *  An observer protocol to receive RZCollectionList change events
 */
@protocol RZCollectionListObserver <NSObject>

@optional

/**
 *  Called every time on object in a collection list changes.
 *
 *  @param collectionList The collection list that changed.
 *  @param object         The object that changed.
 *  @param indexPath      The original index path of the object.
 *  @param type           The RZCollectionListChangeType change type.
 *  @param newIndexPath   The new index path of the object.
 */
- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath;

/**
 *  Called every time a section in a collection list changes.
 *
 *  @param collectionList The collection list that changed.
 *  @param sectionInfo    The section that changed.
 *  @param sectionIndex   The index of the section that changed.
 *  @param type           The RZCollectionListChangeType change type.
 */
- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type;

/**
 *  Called right before the collection list will change its contents.
 *
 *  @param collectionList the collection list that is about to change.
 */
- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList;

/**
 *  Called right after the collection list changed its contents.
 *
 *  @param collectionList The collection list that changed its contents.
 */
- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList;

@end

/**
 *  Implement this protocol to provide information for your collection list. Not required.
 */
@protocol RZCollectionListDelegate <NSObject>

@optional
/**
 *  Provide the section index title for a given section. Often this is shown in the index sidebar of a UITableView.
 *
 *  @param collectionList The collection list requesting this information.
 *  @param sectionName    The name of the section requesting this information.
 *
 *  @return An index title for a particular section.
 */
- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName;

@end



