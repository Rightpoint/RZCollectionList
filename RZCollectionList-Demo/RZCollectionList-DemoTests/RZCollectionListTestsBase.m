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

- (void)waitFor:(NSUInteger)seconds
{
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}


@end
