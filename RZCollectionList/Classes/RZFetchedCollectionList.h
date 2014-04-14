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
#import "RZBaseCollectionList.h"

/**
 *  A type of id<RZCollectionList> to be used when your objects are "fetched" from core data. You may initialize an instance of RZCollectionList with either an NSFetchedResultsController or all of the data we need to create an NSFetchedResultsController for you. Either way, every instance of RZFetchedResultsCollectionList will need non-nil controller property.
 */
@interface RZFetchedCollectionList : RZBaseCollectionList <RZCollectionList>

/**
 *  The controller used to fetch core data objects for this collection list.
 */
@property (nonatomic, strong) NSFetchedResultsController *controller;

/**
 *  Initializer for an RZFetchedCollectionList instance. Takes an NSFetchedResultsController configured to fetch the desired objects from Core Data.
 *
 *  @param controller An NSFetchedResultsController already configured with your Core Data managed object context.
 *
 *  @return An instance of RZFetchedResultsController.
 */
- (id)initWithFetchedResultsController:(NSFetchedResultsController*)controller;

/**
 *  Initializer for an RZFetchedCollectionList instance. Takes all of the objects necessary to data an NSFetchedResultsController configured to fetch the desired objects from Core Data.
 *
 *  @param fetchRequest       An NSFetchRequest configured to fetch a subset of Core Data objects.
 *  @param context            The NSManagedObject context that holds your data.
 *  @param sectionNameKeyPath A key path on result objects that returns the section name for those objects.
 *  @param name               The name of the Core Data cache file the receiver should use. Pass nil to prevent caching.
 *
 *  @return An instance of RZFetchedResultsController.
 */
- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)name;

@end
