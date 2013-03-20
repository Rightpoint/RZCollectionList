//
//  RZCollectionListUIKitDataSourceAdapter.m
//  bhphoto
//
//  Created by Nick Donaldson on 3/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListUIKitDataSourceAdapter.h"
#import "RZObserverCollection.h"

// Uncomment to enable debug log messages
//#define RZCL_SWZ_DEBUG

// ================================================================================================

@interface RZCollectionListSwizzledObjectNotification : NSObject

@property (nonatomic, weak)   id changedObject;

@property (nonatomic, assign) RZCollectionListChangeType changeType;
@property (nonatomic, strong) NSIndexPath *originalIndexPath;
@property (nonatomic, strong) NSIndexPath *originalNewIndexPath;
@property (nonatomic, strong) NSIndexPath *swizzledIndexPath;
@property (nonatomic, strong) NSIndexPath *swizzledNewIndexPath;

- (id)initWithChangeType:(RZCollectionListChangeType)changeType object:(id)object indexPath:(NSIndexPath*)indexPath newIndexPath:(NSIndexPath*)newIndexPath;
- (void)adjustIndexPathSectionBy:(NSInteger)sectionAdjustment rowBy:(NSInteger)rowAdjustment;
- (void)adjustNewIndexPathSectionBy:(NSInteger)sectionAdjustment rowBy:(NSInteger)rowAdjustment;

- (BOOL)existsInArray:(NSArray*)array;

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward;
#endif

@end

@implementation RZCollectionListSwizzledObjectNotification

- (id)initWithChangeType:(RZCollectionListChangeType)changeType object:(id)object indexPath:(NSIndexPath *)indexPath newIndexPath:(NSIndexPath *)newIndexPath
{
    self = [super init];
    if (self) {
        self.changeType = changeType;
        self.originalIndexPath = self.swizzledIndexPath = indexPath;
        self.originalNewIndexPath = self.swizzledNewIndexPath = newIndexPath;
    }
    return self;
}

- (void)adjustIndexPathSectionBy:(NSInteger)sectionAdjustment rowBy:(NSInteger)rowAdjustment
{
    if (self.swizzledIndexPath){
        self.swizzledIndexPath = [NSIndexPath indexPathForRow:self.swizzledIndexPath.row + rowAdjustment inSection:self.swizzledIndexPath.section + sectionAdjustment];
    }
}

- (void)adjustNewIndexPathSectionBy:(NSInteger)sectionAdjustment rowBy:(NSInteger)rowAdjustment
{
    if (self.swizzledNewIndexPath){
        self.swizzledNewIndexPath = [NSIndexPath indexPathForRow:self.swizzledNewIndexPath.row + rowAdjustment inSection:self.swizzledNewIndexPath.section + sectionAdjustment];
    }
}

- (BOOL)existsInArray:(NSArray *)array
{
    __block BOOL exists = NO;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       
        if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
            
            RZCollectionListSwizzledObjectNotification *other = obj;
            if (self.swizzledIndexPath != nil && [other.swizzledIndexPath isEqual:self.swizzledIndexPath]){
                exists = YES;
                *stop = YES;
            }
            else if (self.swizzledNewIndexPath != nil && [other.swizzledNewIndexPath isEqual:self.swizzledNewIndexPath]){
                exists = YES;
                *stop = YES;
            }
        }
        
    }];
    
    return exists;
}

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward
{
    if (self.changeType == RZCollectionListChangeDelete){
        NSLog(@"Sending deletion notification at [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeInsert){
        NSLog(@"Sending insertion notification at [%d, %d]", self.swizzledNewIndexPath.section, self.swizzledNewIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeMove){
        NSLog(@"Sending move notification from [%d, %d] to [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row, self.swizzledNewIndexPath.section, self.swizzledNewIndexPath.row);
    }
    else if (self.changeType == RZCollectionListChangeUpdate){
        NSLog(@"Sending update notification at [%d, %d]", self.swizzledIndexPath.section, self.swizzledIndexPath.row);
    }
}
#endif

@end

// ================================================================================================

@interface RZCollectionListSwizzledSectionNotification : NSObject

@property (nonatomic, weak)     id<RZCollectionListSectionInfo> sectionInfo;
@property (nonatomic, assign)   RZCollectionListChangeType changeType;
@property (nonatomic, assign)   NSInteger originalIndex;
@property (nonatomic, assign)   NSInteger swizzledIndex;

- (id)initWithChangeType:(RZCollectionListChangeType)changeType sectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSInteger)sectionIndex;
- (BOOL)existsInArray:(NSArray*)array;

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward;
#endif

@end

@implementation RZCollectionListSwizzledSectionNotification

-(id)initWithChangeType:(RZCollectionListChangeType)changeType sectionInfo:(id<RZCollectionListSectionInfo>)sectionInfo sectionIndex:(NSInteger)sectionIndex
{
    self = [super init];
    if (self) {
        self.sectionInfo = sectionInfo;
        self.changeType = changeType;
        self.originalIndex = self.swizzledIndex = sectionIndex;
    }
    return self;
}

- (BOOL)existsInArray:(NSArray *)array
{
    __block BOOL exists = NO;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[RZCollectionListSwizzledSectionNotification class]]){
            
            if ([obj swizzledIndex] == self.swizzledIndex){
                exists = YES;
                *stop = YES;
            }
            
        }
    }];
    return exists;
}

#ifdef RZCL_SWZ_DEBUG
- (void)logNotificationForward
{
    if (self.changeType == RZCollectionListChangeDelete){
        NSLog(@"Sending section deletion notification at %d", self.swizzledIndex);
    }
    else if (self.changeType == RZCollectionListChangeInsert){
        NSLog(@"Sending section insertion notification at %d", self.swizzledIndex);
    }
    else if (self.changeType == RZCollectionListChangeMove){
        NSLog(@"Sending section move notification at %d", self.swizzledIndex); // can this happen?
    }
    else if (self.changeType == RZCollectionListChangeUpdate){
        NSLog(@"Sending section update notification at %d", self.swizzledIndex);
    }
}
#endif

@end

// ================================================================================================

@interface RZCollectionListUIKitDataSourceAdapter ()

@property (nonatomic, strong) RZObserverCollection *observerCollection;
@property (nonatomic, strong) NSMutableArray *swizzledObjectRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *swizzledObjectInsertNotifications;
@property (nonatomic, strong) NSMutableArray *swizzledObjectMoveNotifications;
@property (nonatomic, strong) NSMutableArray *swizzledObjectUpdateNotifications;

@property (nonatomic, strong) NSMutableArray *swizzledSectionRemoveNotifications;
@property (nonatomic, strong) NSMutableArray *swizzledSectionInsertNotifications;


@property (nonatomic, weak)   id<RZCollectionList> sourceList;

@property (nonatomic, assign) BOOL isUpdating;

- (void)commonInit;
- (void)forwardObjectUpdateNotifications;

@end

@implementation RZCollectionListUIKitDataSourceAdapter

- (id)init{
    self = [super init];
    if (self){
        [self commonInit];
    }
    return self;
}

- (id)initWithObserver:(id<RZCollectionListObserver>)observer
{
    self = [super init];
    if (self) {
        [self commonInit];
        [self.observerCollection addObject:observer];
    }
    return self;
}

- (void)commonInit
{
    self.observerCollection = [[RZObserverCollection alloc] init];
    
    self.swizzledObjectRemoveNotifications = [NSMutableArray arrayWithCapacity:8];
    self.swizzledObjectInsertNotifications = [NSMutableArray arrayWithCapacity:8];
    self.swizzledObjectMoveNotifications = [NSMutableArray arrayWithCapacity:8];
    self.swizzledObjectUpdateNotifications = [NSMutableArray arrayWithCapacity:8];
    
    self.swizzledSectionRemoveNotifications = [NSMutableArray arrayWithCapacity:8];
    self.swizzledSectionInsertNotifications = [NSMutableArray arrayWithCapacity:8];

}

- (void)addObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection addObject:observer];
}

- (void)removeObserver:(id<RZCollectionListObserver>)observer
{
    [self.observerCollection removeObject:observer];
}

- (void)forwardObjectUpdateNotifications
{
    // Update and move rows
    
    [self.swizzledObjectUpdateNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledObjectNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
                didChangeObject:swizzledNotification.changedObject
                    atIndexPath:swizzledNotification.swizzledIndexPath
                  forChangeType:swizzledNotification.changeType
                   newIndexPath:swizzledNotification.swizzledNewIndexPath];
        }];
        
    }];
    
    [self.swizzledObjectMoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledObjectNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
                didChangeObject:swizzledNotification.changedObject
                    atIndexPath:swizzledNotification.swizzledIndexPath
                  forChangeType:swizzledNotification.changeType
                   newIndexPath:swizzledNotification.swizzledNewIndexPath];
        }];
        
    }];
    
    
    // remove rows, then sections
    
    [self.swizzledObjectRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledObjectNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
                didChangeObject:swizzledNotification.changedObject
                    atIndexPath:swizzledNotification.swizzledIndexPath
                  forChangeType:swizzledNotification.changeType
                   newIndexPath:swizzledNotification.swizzledNewIndexPath];
        }];
        
    }];
    
    
    [self.swizzledSectionRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledSectionNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
               didChangeSection:swizzledNotification.sectionInfo
                        atIndex:swizzledNotification.swizzledIndex
                  forChangeType:swizzledNotification.changeType];
        }];
        
    }];
    
    // Add sections, then rows
    
    [self.swizzledSectionInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledSectionNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
               didChangeSection:swizzledNotification.sectionInfo
                        atIndex:swizzledNotification.swizzledIndex
                  forChangeType:swizzledNotification.changeType];
        }];
        
    }];
    
    [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        RZCollectionListSwizzledObjectNotification *swizzledNotification = obj;
        
#ifdef RZCL_SWZ_DEBUG
        [swizzledNotification logNotificationForward];
#endif
        
        [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj collectionList:self.sourceList
                didChangeObject:swizzledNotification.changedObject
                    atIndexPath:swizzledNotification.swizzledIndexPath
                  forChangeType:swizzledNotification.changeType
                   newIndexPath:swizzledNotification.swizzledNewIndexPath];
        }];
        
    }];
    

    // Remove all notifications
    [self.swizzledObjectRemoveNotifications removeAllObjects];
    [self.swizzledObjectInsertNotifications removeAllObjects];
    [self.swizzledObjectMoveNotifications removeAllObjects];
    [self.swizzledObjectUpdateNotifications removeAllObjects];
    [self.swizzledSectionInsertNotifications removeAllObjects];
    [self.swizzledSectionRemoveNotifications removeAllObjects];
    
#ifdef RZCL_SWZ_DEBUG
    NSLog(@"=================== Completed Message Forwarding ==================");
#endif
    
}

#pragma mark - RZCollectionListObserver

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
 
    RZCollectionListSwizzledObjectNotification *swizzledNotification = [[RZCollectionListSwizzledObjectNotification alloc] initWithChangeType:type object:object indexPath:indexPath newIndexPath:newIndexPath];
    
    // Delete
    if (type == RZCollectionListChangeDelete){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object removal at [%d, %d]", indexPath.section, indexPath.row);
#endif
        // Adjust section index for section deletions first
        __block NSInteger sectionAdjustment = 0;
        [self.swizzledSectionRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
            if (sectionNotification.originalIndex <= indexPath.section){
                sectionAdjustment++;
            }
            
        }];
        
        [self.swizzledSectionInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
            if (sectionNotification.originalIndex <= indexPath.section){
                sectionAdjustment--;
            }
            
        }];
        
        [swizzledNotification adjustIndexPathSectionBy:sectionAdjustment rowBy:0];
        
        
        // Adjust row index for exiting deletions
        __block NSInteger rowAdjustment = 0;
        [self.swizzledObjectRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            if (otherNotification.swizzledIndexPath.section == swizzledNotification.swizzledIndexPath.section && otherNotification.originalIndexPath.row <= indexPath.row){
                rowAdjustment++;
            }
        }];
        
        // Adjust for existing insertions
        [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            
            if(otherNotification.swizzledNewIndexPath.section == swizzledNotification.swizzledIndexPath.section){
                
                if(otherNotification.originalNewIndexPath.row <= indexPath.row){
                    rowAdjustment--;
                }
                else{
                    [otherNotification adjustNewIndexPathSectionBy:0 rowBy:-1];
                }
            }
            
        }];
        
        [swizzledNotification adjustIndexPathSectionBy:0 rowBy:rowAdjustment];
        
        // Avoid duplicates
        if (![swizzledNotification existsInArray:self.swizzledSectionRemoveNotifications]){
            [self.swizzledObjectRemoveNotifications addObject:swizzledNotification];
        }
        
    }
    // Insert
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object insertion at [%d, %d]", newIndexPath.section, newIndexPath.row);
#endif
        __block NSInteger rowAdjustment = 0;
        
        // only need to modify insertions if they happen at the same or lower index

        [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;

            if (otherNotification.swizzledNewIndexPath.section == newIndexPath.section && otherNotification.swizzledNewIndexPath.row >= newIndexPath.row){
                [otherNotification adjustNewIndexPathSectionBy:0 rowBy:1];                
            }
            
        }];
        
        [swizzledNotification adjustNewIndexPathSectionBy:0 rowBy:rowAdjustment];
        
        if (![swizzledNotification existsInArray:self.swizzledObjectInsertNotifications]){
            [self.swizzledObjectInsertNotifications addObject:swizzledNotification];
        }
    }
    else if (type == RZCollectionListChangeUpdate){
        
        // Treat like Removal - need to calculate original index path prior to removals

#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object reload at [%d, %d]", indexPath.section, indexPath.row);
#endif
        
        // Don't allow newly-inserted cells to be updated
        __block BOOL validUpdate = YES;
        [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            if ([otherNotification.originalNewIndexPath isEqual:indexPath]){
                validUpdate = NO;
                *stop = YES;
            }
            
        }];
        
        if (validUpdate){
            
            // Adjust section index for section deletions first
            __block NSInteger sectionAdjustment = 0;
            
            [self.swizzledSectionInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                if (sectionNotification.swizzledIndex <= indexPath.section){
                    sectionAdjustment--;
                }
            }];
            
            [self.swizzledSectionRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                if (sectionNotification.originalIndex <= indexPath.section){
                    sectionAdjustment++;
                }
                
            }];

            
            [swizzledNotification adjustIndexPathSectionBy:sectionAdjustment rowBy:0];
            
            
            __block NSInteger rowAdjustment = 0;
            [self.swizzledObjectRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                if (otherNotification.originalIndexPath.section == indexPath.section && otherNotification.originalIndexPath.row <= indexPath.row){
                    rowAdjustment++;
                }
                
            }];
            
            [swizzledNotification adjustIndexPathSectionBy:0 rowBy:rowAdjustment];
                    
            if (![swizzledNotification existsInArray:self.swizzledObjectUpdateNotifications]){
                [self.swizzledObjectUpdateNotifications addObject:swizzledNotification];
            }
        }
    }
    else if (type == RZCollectionListChangeMove){
        // Treat like Removal - need to calculate original index paths prior to removals
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object move from [%d, %d] to [%d, %d]", indexPath.section, indexPath.row, newIndexPath.section, newIndexPath.row);
#endif
        
        __block NSInteger rowAdjustment = 0;
        __block NSInteger newRowAdjustment = 0;
        [self.swizzledObjectRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;                
            if (otherNotification.originalIndexPath.section == indexPath.section){
                
                if (otherNotification.originalIndexPath.row <= indexPath.row){
                    rowAdjustment++;
                }
                
                if (otherNotification.originalIndexPath.row <= newIndexPath.row){
                    newRowAdjustment++;
                }
            }
            
        }];
        
        [swizzledNotification adjustIndexPathSectionBy:0 rowBy:rowAdjustment];
        [swizzledNotification adjustNewIndexPathSectionBy:0 rowBy:newRowAdjustment];
        
        if (![swizzledNotification existsInArray:self.swizzledObjectMoveNotifications]){
            [self.swizzledObjectMoveNotifications addObject:swizzledNotification];
        }
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    RZCollectionListSwizzledSectionNotification *swizzledNotification = [[RZCollectionListSwizzledSectionNotification alloc] initWithChangeType:type
                                                                                                                                   sectionInfo:sectionInfo
                                                                                                                                  sectionIndex:sectionIndex];
    
    // Delete
    if (type == RZCollectionListChangeDelete){
    
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Section removal at %d", sectionIndex);
#endif
        
        // adjust for existing removals
        [self.swizzledSectionRemoveNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            RZCollectionListSwizzledSectionNotification *otherNotification = obj;
            if (otherNotification.originalIndex <= sectionIndex){
                swizzledNotification.swizzledIndex++;
            }
            
        }];
        
        // adjust for existing insertions
        [self.swizzledSectionInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledSectionNotification *otherNotification = obj;
            if(otherNotification.originalIndex <= sectionIndex){
                swizzledNotification.swizzledIndex--;
            }
            else{
                otherNotification.swizzledIndex--;
            }
            
        }];
        
        // update insertions to reflect change to section
        // does not remove any insertions to the section that just got removed - let it blow up in that case
        [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            
            if (otherNotification.swizzledNewIndexPath.section > swizzledNotification.swizzledIndex){
                [otherNotification adjustNewIndexPathSectionBy:-1 rowBy:0];
            }
            
        }];
        
        if (![swizzledNotification existsInArray:self.swizzledSectionRemoveNotifications]){
            [self.swizzledSectionRemoveNotifications addObject:swizzledNotification];
        }
        
    }
    // Insert
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Section insertion at %d", sectionIndex);
#endif
      
        // move other insertions up by one
        [self.swizzledSectionInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledSectionNotification *otherNotification = obj;
            if (otherNotification.swizzledIndex >= sectionIndex){
                otherNotification.swizzledIndex++;
            }
            
        }];
        
        // move other object insertions up by one
        [self.swizzledObjectInsertNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            RZCollectionListSwizzledObjectNotification *otherNotification = obj;
            
            if (otherNotification.swizzledNewIndexPath.section >= swizzledNotification.swizzledIndex){
                [otherNotification adjustNewIndexPathSectionBy:1 rowBy:0];
            }
            
        }];
        
        if (![swizzledNotification existsInArray:self.swizzledSectionInsertNotifications]){
            [self.swizzledSectionInsertNotifications addObject:swizzledNotification];
        }
    }

}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    self.sourceList = collectionList;
    self.isUpdating = YES;
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListWillChangeContent:collectionList];
    }];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.isUpdating){
        [self forwardObjectUpdateNotifications];
        self.isUpdating = NO;
        self.sourceList = nil;
    }
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListDidChangeContent:collectionList];
    }];
}

@end

