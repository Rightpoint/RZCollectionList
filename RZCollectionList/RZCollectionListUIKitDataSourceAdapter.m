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
#define RZCL_SWZ_DEBUG

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
            if (other.changeType == self.changeType){
                if (self.swizzledIndexPath != nil && [other.swizzledIndexPath isEqual:self.swizzledIndexPath]){
                    exists = YES;
                    *stop = YES;
                }
                else if (self.swizzledNewIndexPath != nil && [other.swizzledNewIndexPath isEqual:self.swizzledNewIndexPath]){
                    exists = YES;
                    *stop = YES;
                }
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
}
#endif

@end

// ================================================================================================

@interface RZCollectionListSwizzledSectionNotification : NSObject

@property (nonatomic, strong)   id<RZCollectionListSectionInfo> sectionInfo;
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
            
            if ([obj changeType] == self.changeType){
                if ([obj swizzledIndex] == self.swizzledIndex){
                    exists = YES;
                    *stop = YES;
                }
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
}
#endif

@end

// ================================================================================================

@interface RZCollectionListUIKitDataSourceAdapter ()

@property (nonatomic, strong) RZObserverCollection *observerCollection;

@property (nonatomic, strong) NSMutableArray *swizzledNotifications;

@property (nonatomic, weak)   id<RZCollectionList> sourceList;

@property (nonatomic, readwrite, assign) BOOL needsReload;
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

    self.swizzledNotifications = [NSMutableArray arrayWithCapacity:100];
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
    
    [self.swizzledNotifications enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
            
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
        }
        else if ([obj isKindOfClass:[RZCollectionListSwizzledSectionNotification class]]){
            
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
        }
    }];

    // Remove all notifications
    [self.swizzledNotifications removeAllObjects];
    
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
        
        [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
                
                RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                
                if (otherNotification.changeType == RZCollectionListChangeDelete){
                    if (otherNotification.originalIndexPath.section == swizzledNotification.swizzledIndexPath.section){
                        if(otherNotification.originalIndexPath.row <= swizzledNotification.swizzledIndexPath.row){
                            [swizzledNotification adjustIndexPathSectionBy:0 rowBy:1];
                        }
                    }
                }
                else if (otherNotification.changeType == RZCollectionListChangeInsert){
                    if(otherNotification.originalNewIndexPath.section == swizzledNotification.swizzledIndexPath.section){
                        if(otherNotification.originalNewIndexPath.row <= swizzledNotification.swizzledIndexPath.row){
                            [swizzledNotification adjustIndexPathSectionBy:0 rowBy:-1];
                        }
                    }
                }
                
            }
            else{
                
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                
                if (sectionNotification.changeType == RZCollectionListChangeInsert){
                    if (sectionNotification.originalIndex <= swizzledNotification.swizzledIndexPath.section){
                        [swizzledNotification adjustIndexPathSectionBy:-1 rowBy:0];
                    }
                }
                else if (sectionNotification.changeType == RZCollectionListChangeDelete){
                    if (sectionNotification.originalIndex <= swizzledNotification.swizzledIndexPath.section){
                        [swizzledNotification adjustIndexPathSectionBy:1 rowBy:0];
                    }
                }
                
            }
        }];
        
        // Avoid duplicates
        if (![swizzledNotification existsInArray:self.swizzledNotifications]){
            
            [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
                    
                    RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                    
                    if (otherNotification.changeType == RZCollectionListChangeInsert){
                        
                        if(otherNotification.originalNewIndexPath.section == swizzledNotification.originalIndexPath.section){
                            
                            if(otherNotification.originalNewIndexPath.row > indexPath.row){
                                [otherNotification adjustNewIndexPathSectionBy:0 rowBy:-1];
                            }
                        }
                    }
                    
                }
            }];
            
            [self.swizzledNotifications addObject:swizzledNotification];
        }
        
    }
    
    // ====== Insert ========
    
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object insertion at [%d, %d]", newIndexPath.section, newIndexPath.row);
#endif        
        
        // don't allow insertions to newly inserted sections
        __block BOOL isValidInsertion = YES;
        [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[RZCollectionListSwizzledSectionNotification class]]){

                RZCollectionListSwizzledSectionNotification *sectionNotificaiton = obj;
                if (sectionNotificaiton.changeType == RZCollectionListChangeInsert){
                    if (newIndexPath.section == sectionNotificaiton.swizzledIndex){
                        isValidInsertion = NO;
                        *stop = YES;
                    }
                }
            }
            
        }];
    

        
        if (isValidInsertion){
            
            [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
                    
                    RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                    
                    if (otherNotification.changeType == RZCollectionListChangeInsert){
                        
                        if (otherNotification.originalNewIndexPath.section == newIndexPath.section){
                            if (newIndexPath.row <= otherNotification.swizzledNewIndexPath.row){
                                [otherNotification adjustNewIndexPathSectionBy:0 rowBy:1];
                            }
                        }
                        
                    }
                    else if (otherNotification.changeType == RZCollectionListChangeMove){
                        
                        if (otherNotification.originalNewIndexPath.section == newIndexPath.section){
                            if (newIndexPath.row <= otherNotification.swizzledNewIndexPath.row){
                                [otherNotification adjustNewIndexPathSectionBy:0 rowBy:1];
                            }
                        }
                        
                    }
                }
            }];
            
            
            if (![swizzledNotification existsInArray:self.swizzledNotifications]){
                [self.swizzledNotifications addObject:swizzledNotification];
            }
        }
    }
    
    // ====== Update ========
    
    else if (type == RZCollectionListChangeUpdate){
        
        // Treat like Removal - need to calculate original index path prior to removals

#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object reload at [%d, %d]", indexPath.section, indexPath.row);
#endif
        
        // just mark as needs reload
        self.needsReload = YES;
    }
    
    // ====== Move ========

    else if (type == RZCollectionListChangeMove){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Object move from [%d, %d] to [%d, %d]", indexPath.section, indexPath.row, newIndexPath.section, newIndexPath.row);
#endif
        // Adjust to find original row, same as a delete
        
        [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
                
                RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                
                if (otherNotification.changeType == RZCollectionListChangeDelete){
                    if (otherNotification.originalIndexPath.section == swizzledNotification.swizzledIndexPath.section){
                        if(otherNotification.originalIndexPath.row <= swizzledNotification.swizzledIndexPath.row){
                            [swizzledNotification adjustIndexPathSectionBy:0 rowBy:1];
                        }
                    }
                }
                else if (otherNotification.changeType == RZCollectionListChangeInsert){
                    if(otherNotification.originalNewIndexPath.section == swizzledNotification.swizzledIndexPath.section){
                        if(otherNotification.originalNewIndexPath.row <= swizzledNotification.swizzledIndexPath.row){
                            [swizzledNotification adjustIndexPathSectionBy:0 rowBy:-1];
                        }
                    }
                }                
            }
            else{
                
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                
                if (sectionNotification.changeType == RZCollectionListChangeInsert){
                    if (sectionNotification.originalIndex <= swizzledNotification.swizzledIndexPath.section){
                        [swizzledNotification adjustIndexPathSectionBy:-1 rowBy:0];
                    }
                }
                else if (sectionNotification.changeType == RZCollectionListChangeDelete){
                    if (sectionNotification.originalIndex <= swizzledNotification.swizzledIndexPath.section){
                        [swizzledNotification adjustIndexPathSectionBy:1 rowBy:0];
                    }
                }
                
            }
        }];
                
        if (![swizzledNotification existsInArray:self.swizzledNotifications]){
            [self.swizzledNotifications addObject:swizzledNotification];
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
      
        [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[RZCollectionListSwizzledSectionNotification class]]){
                
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                
                if (sectionNotification.changeType == RZCollectionListChangeInsert){
                    if(sectionNotification.originalIndex <= sectionIndex){
                        swizzledNotification.swizzledIndex--;
                    }
                }
                else if (sectionNotification.changeType == RZCollectionListChangeDelete){
                    if (sectionNotification.originalIndex <= sectionIndex){
                        swizzledNotification.swizzledIndex++;
                    }
                }
                
            }
        }];
        
        
        if (![swizzledNotification existsInArray:self.swizzledNotifications]){
                    
            // update insertions and deletions to reflect change to section
            // does not remove any insertions to the section that just got removed - let it blow up in that case
            NSMutableArray *deletionsToCancel = [NSMutableArray arrayWithCapacity:8];
            [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                if ([obj isKindOfClass:[RZCollectionListSwizzledObjectNotification class]]){
                    
                    RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                    
                    if (otherNotification.changeType == RZCollectionListChangeDelete){
                        
                        if (otherNotification.swizzledIndexPath.section == swizzledNotification.swizzledIndex){
                            [deletionsToCancel addObject:otherNotification];
                        }
                    }
                    if (otherNotification.changeType == RZCollectionListChangeInsert){
                        if (otherNotification.swizzledNewIndexPath.section > swizzledNotification.originalIndex){
                            [otherNotification adjustNewIndexPathSectionBy:-1 rowBy:0];
                        }
                    }
                    else if (otherNotification.changeType == RZCollectionListChangeMove){
                        
                        if (otherNotification.swizzledNewIndexPath.section > swizzledNotification.originalIndex){
                            [otherNotification adjustNewIndexPathSectionBy:-1 rowBy:0];
                        }
                    }
                }

            }];
            
            [deletionsToCancel enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self.swizzledNotifications removeObject:obj];
            }];
            
            [self.swizzledNotifications addObject:swizzledNotification];

        }
    }
    // Insert
    else if (type == RZCollectionListChangeInsert){
        
#ifdef RZCL_SWZ_DEBUG
        NSLog(@"Section insertion at %d", sectionIndex);
#endif
        
        [self.swizzledNotifications enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([obj isKindOfClass:[RZCollectionListSwizzledSectionNotification class]]){
                
                RZCollectionListSwizzledSectionNotification *sectionNotification = obj;
                
                if (sectionNotification.changeType == RZCollectionListChangeInsert){
                    if (sectionNotification.swizzledIndex >= sectionIndex){
                        sectionNotification.swizzledIndex++;
                    }
                }
                else if (sectionNotification.changeType == RZCollectionListChangeDelete){
                    if (sectionNotification.originalIndex <= sectionIndex){
                        swizzledNotification.swizzledIndex++;
                    }
                }
                
            }
            else{
                RZCollectionListSwizzledObjectNotification *otherNotification = obj;
                
                if (otherNotification.changeType == RZCollectionListChangeInsert){
                    if (otherNotification.swizzledNewIndexPath.section >= swizzledNotification.swizzledIndex){
                        [otherNotification adjustNewIndexPathSectionBy:1 rowBy:0];
                    }
                }
                else if (otherNotification.changeType == RZCollectionListChangeMove){
                    if (otherNotification.swizzledNewIndexPath.section >= swizzledNotification.swizzledIndex){
                        [otherNotification adjustNewIndexPathSectionBy:1 rowBy:0];
                    }
                }
            }
        }];
        
        
        if (![swizzledNotification existsInArray:self.swizzledNotifications]){
            [self.swizzledNotifications addObject:swizzledNotification];
        }
    }

}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    self.sourceList = collectionList;
    self.isUpdating = YES;
    self.needsReload = NO;
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListWillChangeContent:collectionList];
    }];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.isUpdating){
        [self forwardObjectUpdateNotifications];
        self.isUpdating = NO;
    }
    
    [self.observerCollection.allObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj collectionListDidChangeContent:collectionList];
    }];
    
    self.sourceList = nil;
}

@end

