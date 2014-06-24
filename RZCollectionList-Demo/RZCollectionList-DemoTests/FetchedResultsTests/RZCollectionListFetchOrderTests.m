//
//  RZCollectionListFetchOrderTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListFetchOrderTests.h"
#import "TestChildEntity.h"

@interface RZCollectionListFetchOrderTests ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) NSManagedObjectModel *mom;
@property (nonatomic, strong) NSManagedObjectContext *moc;

- (void)insertPairWithName1:(NSString*)name1 name2:(NSString*)name2 index:(NSNumber*)index moc:(NSManagedObjectContext*)moc;

@end

@implementation RZCollectionListFetchOrderTests

- (void)setUp
{
    [super setUp];

    // build CoreData stack
    [super setupCoreDataStack];
}

- (void)tearDown
{
    [super tearDown];
    self.moc = nil;
    self.mom = nil;
    self.psc = nil;
}

- (void)insertPairWithName1:(NSString *)name1 name2:(NSString *)name2 index:(NSNumber *)index moc:(NSManagedObjectContext*)moc
{
    TestChildEntity *tc = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
    tc.name = name1;
    tc.index = index;
    
    tc = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
    tc.name = name2;
    tc.index = index;
}

#pragma mark - Tests

- (void)test100FetchNotificationOrderWithSections
{
    
    // Insert dummy entities, group by index
    [self insertPairWithName1:@"Jack" name2:@"Jill" index:@0 moc:self.moc];
    [self insertPairWithName1:@"Simon" name2:@"Garfunkel" index:@1 moc:self.moc];
    [self insertPairWithName1:@"Bonnie" name2:@"Clyde" index:@2 moc:self.moc];
    [self insertPairWithName1:@"Ben" name2:@"Jerry" index:@3 moc:self.moc];
    [self insertPairWithName1:@"Logistics" name2:@"Nu:Tone" index:@4 moc:self.moc];

    XCTAssertTrue([self.moc save:NULL], @"Failed to save MOC");
    
    NSFetchRequest *fetchReq = [[NSFetchRequest alloc] initWithEntityName:@"TestChildEntity"];
    fetchReq.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchReq
                                                                          managedObjectContext:self.moc
                                                                            sectionNameKeyPath:@"index"
                                                                                     cacheName:nil];
    frc.delegate = self;
    
    XCTAssertTrue([frc performFetch:NULL], @"Fetch failed");
    
    NSArray *obj = [frc fetchedObjects];
    XCTAssertEqual(obj.count, (NSUInteger)10, @"Wrong number of objects");
    
    // dispatch to background thread, child MOC and save to propogate upwards
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // thread-confined moc
        NSManagedObjectContext *bgMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        bgMoc.parentContext = self.moc;
        
        // Fetch current children
        NSFetchRequest *bgFetch = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
        bgFetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
        NSArray *currentChildren = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(currentChildren.count, (NSUInteger)10, @"Fetch of children in background failed");
    
        // fetch first pair, delete them
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 0"];
        NSArray* pair0 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair0.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair0){
            [bgMoc deleteObject:obj];
        }
        
        // fetch second pair, delete them
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 1"];
        NSArray *pair1 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair1.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair1){
            [bgMoc deleteObject:obj];
        }
        
        // group pair with index 3 with index 2
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 3"];
        NSArray* pair3 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair3.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair3){
            [obj setIndex:@2];
        }
        
        // Update name of object in pair 4 - shouldn't move it, just update
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 4"];
        NSArray* pair4 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair4.count, (NSUInteger)2, @"Failed to fetch pair");
        [pair4[0] setName:@"Technicolour"];
        
        // Insert a new pair
        [self insertPairWithName1:@"Cheech" name2:@"Chong" index:@420 moc:bgMoc];
        
        XCTAssertTrue([bgMoc save:NULL], @"Failed to save background MOC");
        
    });
    
}

- (void)test101SimultaneousFetchUpdates
{
    
    // Insert dummy entities, group by index
    [self insertPairWithName1:@"Jack" name2:@"Jill" index:@0 moc:self.moc];
    [self insertPairWithName1:@"Simon" name2:@"Garfunkel" index:@1 moc:self.moc];
    [self insertPairWithName1:@"Bonnie" name2:@"Clyde" index:@2 moc:self.moc];
    [self insertPairWithName1:@"Ben" name2:@"Jerry" index:@3 moc:self.moc];
    [self insertPairWithName1:@"Logistics" name2:@"Nu:Tone" index:@4 moc:self.moc];
    
    XCTAssertTrue([self.moc save:NULL], @"Failed to save MOC");
    
    // Fetch 1 - index <= 2
    NSFetchRequest *fetchReq1 = [[NSFetchRequest alloc] initWithEntityName:@"TestChildEntity"];
    fetchReq1.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    fetchReq1.predicate = [NSPredicate predicateWithFormat:@"index <= 2"];
    
    NSFetchedResultsController *frc1 = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchReq1
                                                                          managedObjectContext:self.moc
                                                                            sectionNameKeyPath:@"index"
                                                                                     cacheName:nil];
    frc1.delegate = self;
    
    // Fetch 2 - index > 2
    NSFetchRequest *fetchReq2 = [[NSFetchRequest alloc] initWithEntityName:@"TestChildEntity"];
    fetchReq2.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                                  [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    fetchReq2.predicate = [NSPredicate predicateWithFormat:@"index > 2"];
    
    NSFetchedResultsController *frc2 = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchReq2
                                                                           managedObjectContext:self.moc
                                                                             sectionNameKeyPath:@"index"
                                                                                      cacheName:nil];
    frc2.delegate = self;
    
    XCTAssertTrue([frc1 performFetch:NULL], @"Fetch 1 failed");
    XCTAssertTrue([frc2 performFetch:NULL], @"Fetch 2 failed");
    
    NSArray *obj1 = [frc1 fetchedObjects];
    XCTAssertEqual(obj1.count, (NSUInteger)6, @"Wrong number of objects for fetch 1");
    
    NSArray *obj2 = [frc2 fetchedObjects];
    XCTAssertEqual(obj2.count, (NSUInteger)4, @"Wrong number of objects for fetch 2");
    
    // dispatch to background thread, child MOC and save to propogate upwards
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // thread-confined moc
        NSManagedObjectContext *bgMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        bgMoc.parentContext = self.moc;
        
        // Fetch current children
        NSFetchRequest *bgFetch = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
        bgFetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
        NSArray *currentChildren = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(currentChildren.count, (NSUInteger)10, @"Fetch of children in background failed");
        
        // fetch first pair, delete them
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 0"];
        NSArray* pair0 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair0.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair0){
            [bgMoc deleteObject:obj];
        }
        
        // fetch second pair, delete them
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 1"];
        NSArray *pair1 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair1.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair1){
            [bgMoc deleteObject:obj];
        }
        
        // group pair with index 3 with index 2
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 3"];
        NSArray* pair3 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair3.count, (NSUInteger)2, @"Failed to fetch pair");
        for (id obj in pair3){
            [obj setIndex:@2];
        }
        
        // Update name of object in pair 4 - shouldn't move it, just update
        bgFetch.predicate = [NSPredicate predicateWithFormat:@"index == 4"];
        NSArray* pair4 = [bgMoc executeFetchRequest:bgFetch error:NULL];
        XCTAssertEqual(pair4.count, (NSUInteger)2, @"Failed to fetch pair");
        [pair4[0] setName:@"Technicolour"];
        
        // Insert a new pair
        [self insertPairWithName1:@"Cheech" name2:@"Chong" index:@420 moc:bgMoc];
        
        XCTAssertTrue([bgMoc save:NULL], @"Failed to save background MOC");
        
    });
    
}

#pragma mark - Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"%@ WILL CHANGE", controller);
    NSLog(@"%@ CURRENT CONTENTS: %@", controller, [controller fetchedObjects]);
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"%@ DID CHANGE", controller);
    NSLog(@"%@ CURRENT CONTENTS: %@", controller, [controller fetchedObjects]);
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeDelete:
            NSLog(@"%@ DELETED OBJECT AT %@ : %@", controller, indexPath, anObject);
            break;
            
        case NSFetchedResultsChangeInsert:
            NSLog(@"%@ INSERTED OBJECT AT %@ : %@", controller, newIndexPath, anObject);
            break;
            
        case NSFetchedResultsChangeMove:
            NSLog(@"%@ MOVED OBJECT FROM %@ TO %@ : %@", controller, indexPath, newIndexPath, anObject);
            break;
            
        case NSFetchedResultsChangeUpdate:
            NSLog(@"%@ UPDATED OBJECT AT %@ : %@", controller, indexPath, anObject);
            break;
        
            
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
            
        case NSFetchedResultsChangeDelete:
            NSLog(@"%@ DELETED SECTION AT INDEX %lu", controller, (unsigned long)sectionIndex);
            break;
            
        case NSFetchedResultsChangeInsert:
            NSLog(@"%@ INSERTED SECTION AT INDEX %lu", controller, (unsigned long)sectionIndex);
            break;
            
        default:
            break;
    }
}

@end
