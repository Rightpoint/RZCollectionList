//
//  RZCollectionListFetchedListComboTests.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZFetchedCollectionListComboTests.h"

@interface RZFetchedCollectionListComboTests ()

@property (nonatomic, strong) RZFetchedCollectionList *fetchedList;
@property (nonatomic, strong) RZFilteredCollectionList *filteredList;
@property (nonatomic, strong) RZSortedCollectionList *sortedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *dataSource;

@end

@implementation RZFetchedCollectionListComboTests

- (void)setUp
{
    [super setUp];
    [self setupTableView];
    [self setupCoreDataStack];
}

- (void)tearDown
{
    [self waitFor:1];
    [super tearDown];
}

#pragma mark - Table Data Source Delegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    if ([object isKindOfClass:[TestChildEntity class]])
    {
        cell.textLabel.text = [object name];
        cell.detailTextLabel.text = [[object index] stringValue];
    }
    return cell;
}

#pragma mark - Tests

- (void)test100FetchWithFilter
{
    [self insertTestObjectsToMoc];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                              [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                                          managedObjectContext:self.moc
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    
    self.fetchedList = [[RZFetchedCollectionList alloc] initWithFetchedResultsController:frc];
    self.filteredList = [[RZFilteredCollectionList alloc] initWithSourceList:self.fetchedList predicate:nil];
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.filteredList
                                                                            delegate:self];
    
    [self waitFor:1];
    
    // change the filter - even indices only
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ([[evaluatedObject index] integerValue] % 2 == 0);
    }];
    XCTAssertNoThrow( self.filteredList.predicate = predicate, @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[@"Iggy", @"Gretchen", @"Edgar", @"Carl", @"Arthur"]];
    
    [self waitFor:1];

    // insert some new homeys at even indexes, delete a few others
    RZCollectionListTestCoreDataBlock bgBlock = ^(NSManagedObjectContext *moc) {
        
        TestChildEntity *nuChild = nil;
        
        nuChild = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
        nuChild.name = @"Nuni";
        nuChild.index = @2;
        
        nuChild = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
        nuChild.name = @"Kai";
        nuChild.index = @8;
        
        // Kill gretchen
        NSFetchRequest *gretchenFetchen = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
        gretchenFetchen.predicate = [NSPredicate predicateWithFormat:@"name == %@", @"Gretchen"];
        NSArray *gretchenResults = [moc executeFetchRequest:gretchenFetchen error:NULL];
        XCTAssertTrue(gretchenResults.count != 0, @"Couldn't Find Gretchen");
        if (gretchenResults.count > 0){
            TestChildEntity *gretchen = gretchenResults[0];
            [moc deleteObject:gretchen];
        }
        
    };
    
    XCTAssertNoThrow([self performSynchronousCoreDataBlockInChildContext:bgBlock], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:@[@"Iggy", @"Nuni", @"Edgar", @"Carl", @"Kai", @"Arthur"]];
    
    [self waitFor:1];
}

- (void)test101FetchWithSort
{
    [self insertTestObjectsToMoc];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                              [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                                          managedObjectContext:self.moc
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    
    // Fetch with ascending index, sort by descending index.
    
    self.fetchedList = [[RZFetchedCollectionList alloc] initWithFetchedResultsController:frc];
    self.sortedList = [[RZSortedCollectionList alloc] initWithSourceList:self.fetchedList
                                                         sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO],
                                                                           [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.sortedList
                                                                            delegate:self];
    
    [self assertTitlesOfVisibleCells:
     @[ @"Arthur",
        @"Barb",
        @"Carl",
        @"Denny",
        @"Edgar",
        @"Filburt",
        @"Gretchen",
        @"Horatio",
        @"Iggy",
        @"Jasper"]
     ];
    
    [self waitFor:1];
    
    // insert some new homeys at even indexes, delete a few others
    RZCollectionListTestCoreDataBlock bgBlock = ^(NSManagedObjectContext *moc) {
        
        TestChildEntity *nuChild = nil;
        
        nuChild = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
        nuChild.name = @"Nuni";
        nuChild.index = @2;
        
        nuChild = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:moc];
        nuChild.name = @"Kai";
        nuChild.index = @8;
        
        // Kill gretchen
        NSFetchRequest *gretchenFetchen = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
        gretchenFetchen.predicate = [NSPredicate predicateWithFormat:@"name == %@", @"Gretchen"];
        NSArray *gretchenResults = [moc executeFetchRequest:gretchenFetchen error:NULL];
        XCTAssertTrue(gretchenResults.count != 0, @"Couldn't Find Gretchen");
        if (gretchenResults.count > 0){
            TestChildEntity *gretchen = gretchenResults[0];
            [moc deleteObject:gretchen];
        }
        
    };
    
    XCTAssertNoThrow([self performSynchronousCoreDataBlockInChildContext:bgBlock], @"Something went wrong");
    
    [self assertTitlesOfVisibleCells:
     @[ @"Arthur",
        @"Barb",
        @"Carl",
        @"Kai",
        @"Denny",
        @"Edgar",
        @"Filburt",
        @"Horatio",
        @"Iggy",
        @"Nuni",
        @"Jasper"]
     ];
    
    
}

- (void)test101FetchWithSortChangeDescriptors
{
    [self insertTestObjectsToMoc];
    
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"TestChildEntity"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES],
                              [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                                          managedObjectContext:self.moc
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];
    
    // Fetch with ascending index, sort by descending index.
    
    self.fetchedList = [[RZFetchedCollectionList alloc] initWithFetchedResultsController:frc];
    self.sortedList = [[RZSortedCollectionList alloc] initWithSourceList:self.fetchedList
                                                         sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO],
                       [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView
                                                                      collectionList:self.sortedList
                                                                            delegate:self];
    
    NSArray *orderedNames =  @[ @"Arthur",
                                @"Barb",
                                @"Carl",
                                @"Denny",
                                @"Edgar",
                                @"Filburt",
                                @"Gretchen",
                                @"Horatio",
                                @"Iggy",
                                @"Jasper"];
    
    [self assertTitlesOfVisibleCells:orderedNames];
    
    [self waitFor:1];
    
    // swap order by changing sort descriptor
    [self.sortedList setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    
    [self assertTitlesOfVisibleCells:[[orderedNames reverseObjectEnumerator] allObjects]];
}

@end
