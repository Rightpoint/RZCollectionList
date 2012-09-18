//
//  DemoCollectionListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "DemoCollectionListViewController.h"
#import "RZCollectionList.h"
#import "RZFetchedCollectionList.h"
#import "RZArrayCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ListItem.h"
#import "ListItemObject.h"
#import "NSFetchRequest+RZCreationHelpers.h"
#import "AppDelegate.h"

@interface DemoCollectionListViewController () <RZCollectionListDataSourceDelegate>

- (NSArray*)listItemObjects;

@end

@implementation DemoCollectionListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // RZFetchedCollectionList DEMO
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ListItem" sortDescriptorKey:@"itemName" ascending:YES];
    RZFetchedCollectionList *fetchedList = [[RZFetchedCollectionList alloc] initWIthFetchRequest:request
                                                                            managedObjectContext:[[AppDelegate appDelegate] managedObjectContext]
                                                                              sectionNameKeyPath:@"subtitle"
                                                                                       cacheName:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:fetchedList delegate:self];
    
    
    // RZArrayCollectionList DEMO
    
//    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:[self listItemObjects] sectionNameKeyPath:@"subtitle"];
//    
//    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:arrayList delegate:self];
}

- (NSArray*)listItemObjects
{
    return @[[ListItemObject listItemObjectWithName:@"Item 0" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 1" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 2" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 3" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 4" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 5" subtitle:@"1 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 6" subtitle:@"2 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 7" subtitle:@"2 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 8" subtitle:@"2 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 9" subtitle:@"2 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 10" subtitle:@"2 Subtitle"],
             [ListItemObject listItemObjectWithName:@"Item 11" subtitle:@"2 Subtitle"]
    ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"DemoCellIdentifier";
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    ListItem *item = (ListItem*)object;
    
    if ([item isKindOfClass:[ListItem class]] || [item isKindOfClass:[ListItemObject class]])
    {
        cell.textLabel.text = item.itemName;
        cell.detailTextLabel.text = item.subtitle;
    }
    
    return cell;
}

@end
