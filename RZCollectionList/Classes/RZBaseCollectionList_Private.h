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

@interface RZBaseCollectionList ()

@property (nonatomic, strong) RZObserverCollection *collectionListObservers;

// these will be used to cache section/object changes during an update. Do not insert in these directly - use helpers below.
@property (nonatomic, strong) NSMutableArray *pendingSectionInsertNotifications;
@property (nonatomic, strong) NSMutableArray *pendingSectionRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectInsertNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectMoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectUpdateNotifications;

// Returns concatenation of all pending notifications
@property (nonatomic, readonly) NSArray *allPendingObjectNotifications;
@property (nonatomic, readonly) NSArray *allPendingSectionNotifications;

- (void)addCollectionListObserver:(id<RZCollectionListObserver>)listObserver;
- (void)removeCollectionListObserver:(id<RZCollectionListObserver>)listObserver;

//! Helpers for enqueuing pending updates
- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type;
- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type;

//! Sorts pending notifications by index/indexPath, depending on type.
// This is automatically called when calling sendAllPendingChangeNotifications.
- (void)sortPendingNotifications;

//! Send will change notifications
- (void)sendWillChangeContentNotifications;

//! Send did change notifications
- (void)sendDidChangeContentNotifications;

//! Sends out all pending notifications in the expected order
- (void)sendAllPendingChangeNotifications;

/*! 
    If a subclass does not use sendObjectAndSectionNotificationsToObservers:,
    it MUST call this method after notifications are sent and no longer needed
    in order to clear out the pending notifications for the next update.
*/
- (void)resetPendingNotifications;

// Notification Helpers
- (void)sendSectionNotifications:(NSArray *)sectionNotifications;
- (void)sendObjectNotifications:(NSArray *)objectNotifications;


@end
