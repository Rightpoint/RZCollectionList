//
//  TestParentEntity.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestChildEntity;

@interface TestParentEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *children;
@end

@interface TestParentEntity (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(TestChildEntity *)value;
- (void)removeChildrenObject:(TestChildEntity *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
