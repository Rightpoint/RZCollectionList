//
//  RZBaseCollectionList_Private.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZBaseCollectionList.h"
#import "RZCollectionListNotificationWrappers.h"

// Max number of notifications to keep around for reuse.
// Exceeding this number in a single batch update will cause new allocations.
// This can be fairly generous since notification objects are pretty small.
#define kRZCollectionListNotificationReuseCacheMaxSize 64

@interface RZBaseCollectionList ()

// these will be used to cache section/object changes during an update. Do not insert in these directly - use helpers below.
@property (nonatomic, strong) NSMutableArray *pendingSectionInsertNotifications;
@property (nonatomic, strong) NSMutableArray *pendingSectionRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectInsertNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectMoveNotifications;
@property (nonatomic, strong) NSMutableArray *pendingObjectUpdateNotifications;

//! Helpers for enqueuing pending updates
- (void)enqueueObjectNotificationWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type;
- (void)enqueueSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type;

//! Sorts pending notifications by index/indexPath, depending on type
- (void)sortPendingNotifications;

//! Send will change notifications
- (void)sendWillChangeNotificationsToObservers:(NSArray*)observers;

//! Send did change notifications
- (void)sendDidChangeNotificationsToObservers:(NSArray*)observers;

//! Sends out all pending notifications in the expected order
- (void)sendPendingNotificationsToObservers:(NSArray*)observers;

/*! 
    If a subclass does not use sendObjectAndSectionNotificationsToObservers:,
    it MUST call this method after notifications are sent and no longer needed
    in order to clear out the pending notifications for the next update.
*/
- (void)resetPendingNotifications;

// Notification Helpers
- (void)sendSectionNotifications:(NSArray *)sectionNotifications toObservers:(NSArray*)observers;
- (void)sendObjectNotifications:(NSArray *)objectNotifications toObservers:(NSArray*)observers;


@end
