//
//  SortedListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "SortedListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ListItemObject.h"

@interface SortedListViewController () <RZCollectionListDataSourceDelegate>

@property (nonatomic, strong) RZSortedCollectionList *sortedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listDataSource;

- (NSArray*)listItemObjects;

- (NSArray*)sortDescriptorsForSegmentValue:(NSUInteger)segmentValue;

@end

@implementation SortedListViewController

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
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:[self listItemObjects] sectionNameKeyPath:@"subtitle"];
    NSArray *sortDescriptors = [self sortDescriptorsForSegmentValue:self.sortSegmentControl.selectedSegmentIndex];
    self.sortedList = [[RZSortedCollectionList alloc] initWithSourceList:arrayList sortDescriptors:sortDescriptors];
    self.listDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.sortedList delegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*)listItemObjects
{
    NSUInteger numItems = 100;
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:numItems];
    
    for (int i=0; i < numItems; ++i)
    {
        NSString *itemName = [NSString stringWithFormat:@"Item %d", i];
        NSString *itemSubtitle = [NSString stringWithFormat:@"%d Subtitle", i % 6];
        [items addObject:[ListItemObject listItemObjectWithName:itemName subtitle:itemSubtitle]];
    }
    
    return items;
}

- (NSArray*)sortDescriptorsForSegmentValue:(NSUInteger)segmentValue
{
    NSArray *sortDescriptors = nil;
    
    switch (segmentValue) {
        case 0:
            sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES]];
            break;
        case 1:
            sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:NO]];
            break;
        case 2:
            sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"subtitle" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"itemName" ascending:YES]];
            break;
            
        default:
            break;
    }
    
    return sortDescriptors;
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SortedCellIdentifier";
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    ListItemObject *item = (ListItemObject*)object;
    
    if ([item isKindOfClass:[ListItemObject class]])
    {
        cell.textLabel.text = item.itemName;
        cell.detailTextLabel.text = item.subtitle;
    }
    
    return cell;
}

#pragma mark - Action Methods

- (IBAction)sortSegmentControlChanged:(id)sender
{
    NSUInteger segmentIndex = self.sortSegmentControl.selectedSegmentIndex;
    NSArray *sortDescriptors = [self sortDescriptorsForSegmentValue:segmentIndex];
    self.sortedList.sortDescriptors = sortDescriptors;
}
@end
