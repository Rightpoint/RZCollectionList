//
//  RZCollectionListTestsBase.m
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import "RZCollectionListTestsBase.h"

@implementation RZCollectionListTestsBase

- (void)tearDown
{
    [super tearDown];
    self.moc = nil;
    self.mom = nil;
    self.psc = nil;
    self.viewController = nil;
    self.tableView = nil;
}

- (void)setupTableView
{
    self.viewController = [[UIViewController alloc] init];
    [self.viewController view];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.viewController.view.bounds];
    [self.viewController.view addSubview:self.tableView];
    self.tableView.userInteractionEnabled = NO;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    self.viewController.title = @"Table View Tests";
    self.viewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:nav];
}

- (void)setupCoreDataStack
{
    NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"RZCollectionListFetchTestModel" withExtension:@"momd"];
    self.mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    self.psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.mom];
    [self.psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    
    self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.moc setPersistentStoreCoordinator:self.psc];
}


- (void)insertTestObjectsToMoc
{
    NSArray *testData = @[ @[@"Arthur",     @10],
                           @[@"Barb",       @9],
                           @[@"Carl",       @8],
                           @[@"Denny",      @7],
                           @[@"Edgar",      @6],
                           @[@"Filburt",    @5],
                           @[@"Gretchen",   @4],
                           @[@"Horatio",    @3],
                           @[@"Iggy",       @2],
                           @[@"Jasper",     @1] ];
    
    for (NSArray *childInfo in testData)
    {
        TestChildEntity *child = [NSEntityDescription insertNewObjectForEntityForName:@"TestChildEntity" inManagedObjectContext:self.moc];
        child.name = childInfo[0];
        child.index = childInfo[1];
    }
    
    XCTAssertTrue([self.moc save:NULL], @"Failed to save MOC");
}


- (void)performSynchronousCoreDataBlockInChildContext:(RZCollectionListTestCoreDataBlock)block
{
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSManagedObjectContext *bgMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [bgMoc setParentContext:self.moc];
        
        block(bgMoc);
        
        XCTAssertTrue([bgMoc save:NULL], @"Failed to save child MOC");
        
    });
}

- (void)waitFor:(NSUInteger)seconds
{
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (void)assertTitlesOfVisibleCells:(NSArray *)titles
{
    NSArray *visibleTitles = [self.tableView.visibleCells valueForKeyPath:@"textLabel.text"];
    XCTAssertTrue(visibleTitles.count <= titles.count, @"Too many visible cells for provided titles");
    if (visibleTitles.count < titles.count){
        
        // trim titles to length of visible cells
        titles = [titles subarrayWithRange:NSMakeRange(0, visibleTitles.count)];
    }
    
    XCTAssertEqualObjects(visibleTitles, titles, @"Titles do not match expected titles");
}


@end
