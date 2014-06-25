//
//  RZBaseCollectionList_Private.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseCollectionList.h"
#import "RZObserverCollection.h"
#import "RZCollectionListNotificationWrappers.h"

/**
 *  Private class continuation header for RZBaseCollectionList.
 *  Do not use these methods publicly.
 */
@interface RZBaseCollectionList ()
{
    // Exposed so subclasses can override delegate setter if desired.
    @protected
    __weak id<RZCollectionListDelegate> _delegate;
}

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

/**
 *  These will be used to cache section/object changes during an update. 
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingSectionInsertNotifications;

/**
 *  These will be used to cache section/object changes during an update.
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingSectionRemoveNotifications;

/**
 *  These will be used to cache section/object changes during an update.
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingObjectInsertNotifications;

/**
 *  These will be used to cache section/object changes during an update.
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingObjectRemoveNotifications;

/**
 *  These will be used to cache section/object changes during an update.
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingObjectMoveNotifications;

/**
 *  These will be used to cache section/object changes during an update.
 * @warning Do not insert in these directly - use helpers below.
 */
@property (nonatomic, strong) NSMutableArray *pendingObjectUpdateNotifications;

/**
 *  Returns concatenation of all pending object notifications
 */
@property (nonatomic, readonly) NSArray *allPendingObjectNotifications;

/**
 *  Returns concatenation of all pending section notifications
 */
@property (nonatomic, readonly) NSArray *allPendingSectionNotifications;

/**
 *  Add an observer to this id<RZColectionList> instance.
 *
 *  @param listObserver The observer that conforms to the RZCollectionListObserver protocol.
 */
- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

/**
 *  Remove an observer to this id<RZColectionList> instance.
 *
 *  @param listObserver The observer that conforms to the RZCollectionListObserver protocol.
 */
- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

#pragma mark - Helpers for enqueuing pending updates

/**
 *  Create a notification for a cached object
 *
 *  @param object       The object of the notification.
 *  @param indexPath    The current index path for the object.
 *  @param newIndexPath The new index path for the object.
 *  @param type         The type of change for the object. A RZCollectionListChangeType enumerated type.
 */
- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type;

/**
 *  Create a notification for a cached object
 *
 *  @param object       The object of the notification.
 *  @param indexPath    The current index path for the object.
 *  @param newIndexPath The new index path for the object.
 *  @param type         The type of change for the object. A RZCollectionListChangeType enumerated type.
 *  @param list         The source list that contains the object. An instance of RZCollectionList.
 */
- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list;

/**
 *  Create a notification for a cached section
 *
 *  @param sectionInfo  Description for the section. Any object that conforms to the RZCollectionListSectionInfo protocol.
 *  @param sectionIndex The index of the section.
 *  @param type         The type of change for the section. A RZCollectionListChangeType enumerated type.
 */
- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type;

/**
 *  Create a notification for a cached section
 *
 *  @param sectionInfo  Description for the section. Any object that conforms to the RZCollectionListSectionInfo protocol.
 *  @param sectionIndex The index of the section.
 *  @param type         The type of change for the section. A RZCollectionListChangeType enumerated type.
 *  @param list         The source list that contains the section. An instance of RZCollectionList.
 */
- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list;

/**
 *  Sorts pending notifications by index/indexPath, depending on type.
 *  @note sendAllPendingChangeNotifications will automatically call this
 */
- (void)sortPendingNotifications;

/**
 *  Send will change notifications
 */
- (void)sendWillChangeContentNotifications;

/**
 *  Send did change notifications
 */
- (void)sendDidChangeContentNotifications;

/**
 *  Sends out all pending notifications in the expected order
 */
- (void)sendAllPendingChangeNotifications;

/**
 *  Clear out and reset the pending notification cache
 *  @note sendAllPendingChangeNotifications will automatically call this
 */
- (void)resetPendingNotifications;

#pragma mark - Notification Helpers

/**
 *  Sends section notifications to all observers of this list that conform to RZCollectionListObserver
 *
 *  @param sectionNotifications An array of RZCollectionListSectionNotification objects
 */
- (void)sendSectionNotifications:(NSArray *)sectionNotifications;

/**
 *  Sends object notifications to all observers of this list that conform to RZCollectionListObserver
 *
 *  @param objectNotifications An array of RZCollectionListObjectNotification objects
 */
- (void)sendObjectNotifications:(NSArray *)objectNotifications;

@end
