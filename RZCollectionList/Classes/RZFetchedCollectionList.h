//
//  RZFetchedCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RZCollectionListProtocol.h"
#import "RZBaseSourceCollectionList.h"

@interface RZFetchedCollectionList : RZBaseSourceCollectionList <RZCollectionList>

@property (nonatomic, strong) NSFetchedResultsController *controller;

- (id)initWithFetchedResultsController:(NSFetchedResultsController*)controller;
- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)name;

@end
