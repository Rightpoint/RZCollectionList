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
// Left fairly generous since notification objects are pretty small.
#define kRZCollectionListNotificationReuseCacheMaxSize 128

@interface RZBaseCollectionList ()

// batch update object cache containers

// these should be used to cache contents of the current collection or
// an observed collection prior to mutating the internal state
@property (nonatomic, strong) NSArray *sourceSectionsInfoBeforeUpdateDeep;       // deep-copies - range/offset will not change during update
@property (nonatomic, strong) NSArray *sourceSectionsInfoBeforeUpdateShallow;    // shallow-copies - same as the sectionInfo objects that are being updated
@property (nonatomic, strong) NSArray *sourceObjectsBeforeUpdate;

// these should be used to cache section/object changes during an update
@property (nonatomic, strong) NSMutableSet *pendingSectionInsertNotifications;
@property (nonatomic, strong) NSMutableSet *pendingSectionRemoveNotifications;
@property (nonatomic, strong) NSMutableSet *pendingObjectInsertNotifications;
@property (nonatomic, strong) NSMutableSet *pendingObjectRemoveNotifications;
@property (nonatomic, strong) NSMutableSet *pendingObjectMoveNotifications;
@property (nonatomic, strong) NSMutableSet *pendingObjectUpdateNotifications;

@property (nonatomic, strong) NSMutableSet *sectionNotificationReuseCache;
@property (nonatomic, strong) NSMutableSet *objectNotificationReuseCache;

- (RZCollectionListObjectNotification*)dequeueReusableObjectNotification;
- (RZCollectionListSectionNotification*)dequeueReusableSectionNotification;

// Subclasses can call this to send out all pending notifications in the expected order
- (void)sendObjectAndSectionNotificationsToObservers:(NSArray*)observers;

// If a subclass does not use sendObjectAndSectionNotificationsToObservers:,
// it MUST call this method after notifications are sent and no longer needed
// in order to reset the pending notification sets.
- (void)resetPendingNotifications;

// Notification Helpers
- (void)sendSectionNotifications:(NSArray *)sectionNotifications toObservers:(NSArray*)observers;
- (void)sendObjectNotifications:(NSArray *)objectNotifications toObservers:(NSArray*)observers;



@end
