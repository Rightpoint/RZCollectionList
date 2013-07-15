//
//  RZBaseCollectionList_Protected.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//


/***********************************************************************
*
*   This is the protected class extension header for RZBaseCollectionList.
*
*   Subclasses of RZBaseCollectionList should import this header in the
*   source file, not in the header file. These methods should not be made
*   publicly accessible.
*
*************************************************************************/

#import "RZBaseCollectionList.h"
#import "RZObserverCollection.h"
#import "RZCollectionListNotificationWrappers.h"

@interface RZBaseCollectionList ()
{
    // Exposed so subclasses can override delegate setter if desired.
    @protected
    __weak id<RZCollectionListDelegate> _delegate;
}

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
- (void)cacheObjectNotificationWithObject:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list;
- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type;
- (void)cacheSectionNotificationWithSectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSUInteger)sectionIndex type:(RZCollectionListChangeType)type sourceList:(id<RZCollectionList>)list;

//! Sorts pending notifications by index/indexPath, depending on type.
/*!
    sendAllPendingChangeNotifications will automatically call this
*/
- (void)sortPendingNotifications;

//! Send will change notifications
- (void)sendWillChangeContentNotifications;

//! Send did change notifications
- (void)sendDidChangeContentNotifications;

//! Sends out all pending notifications in the expected order
- (void)sendAllPendingChangeNotifications;

//! Clear out and reset the pending notification cache
/*! 
    sendAllPendingChangeNotifications will automatically call this
*/
- (void)resetPendingNotifications;

// Notification Helpers
- (void)sendSectionNotifications:(NSArray *)sectionNotifications;
- (void)sendObjectNotifications:(NSArray *)objectNotifications;


@end
