//
//  RZCollectionListNotificationWrappers.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListNotificationWrappers.h"

@implementation RZCollectionListSectionNotification

- (id)init
{
    if ((self = [super init]))
    {
        [self clear];
    }
    return self;
}

- (void)clear
{
    self.sectionInfo = nil;
    self.type = RZCollectionListChangeInvalid;
    self.sectionIndex = NSNotFound;
    self.sourceList = nil;
}

- (void)sendToObservers:(NSArray*)observers fromCollectionList:(id<RZCollectionList>)list
{
    [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionList:list didChangeSection:self.sectionInfo atIndex:self.sectionIndex forChangeType:self.type];
        }
        
    }];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ Section Info: %@ Section Index: %ld Type %d", [super description], self.sectionInfo, self.sectionIndex, self.type];
}

@end

@implementation RZCollectionListObjectNotification

- (id)init
{
    if ((self = [super init]))
    {
        [self clear];
    }
    return self;
}

- (void)clear
{
    self.object = nil;
    self.indexPath = nil;
    self.nuIndexPath = nil;
    self.type = RZCollectionListChangeInvalid;
    self.sourceList = nil;
}

- (void)sendToObservers:(NSArray*)observers fromCollectionList:(id<RZCollectionList>)list
{
    [observers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(RZCollectionListObserver)])
        {
            [obj collectionList:list didChangeObject:self.object atIndexPath:self.indexPath forChangeType:self.type newIndexPath:self.nuIndexPath];
        }
        
    }];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ Object: %@ Index Path: %@ New Index Path: %@ Type: %d", [super description], self.object, self.indexPath, self.nuIndexPath, self.type];
}

@end