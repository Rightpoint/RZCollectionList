//
//  TestChildEntity.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TestChildEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSManagedObject *parent;

@end
