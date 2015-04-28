//
//  RZCollectionListNotificationWrappers.h
//  RZCollectionList
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListProtocol.h"

// Box containers for storing fetched results controller notifications until didChange is called.
// This is to obey the internal ordering protocol for batch update notifications in RZCollectionList
// See wiki for details: https://github.com/Raizlabs/RZCollectionList/wiki/Batch-Notification-Order

@interface RZCollectionListSectionNotification : NSObject

@property (nonatomic, strong) id<RZCollectionListSectionInfo> sectionInfo;
@property (nonatomic, assign) NSUInteger sectionIndex;
@property (nonatomic, assign) RZCollectionListChangeType type;
@property (nonatomic, weak)   id<RZCollectionList> sourceList;

- (void)clear;
- (void)sendToObservers:(NSArray*)observers fromCollectionList:(id<RZCollectionList>)list;

@end

@interface RZCollectionListObjectNotification : NSObject

@property (nonatomic, strong) id object;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) NSIndexPath *nuIndexPath; // dumb spelling, but avoids cocoa naming convention build error (synthesized getter can't start with "new")
@property (nonatomic, assign) RZCollectionListChangeType type;
@property (nonatomic, weak)   id<RZCollectionList> sourceList;

- (void)clear;
- (void)sendToObservers:(NSArray*)observers fromCollectionList:(id<RZCollectionList>)list;

@end
