//
//  CompositeListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/30/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "CompositeListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZCompositeCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ListItemObject.h"

@interface CompositeListViewController () <RZCollectionListDataSourceDelegate>

@property (nonatomic, strong) RZArrayCollectionList *dynamicList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *dataSource;

@end

@implementation CompositeListViewController

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
    self.navigationItem.rightBarButtonItem = self.addButton;
    
    RZArrayCollectionList *staticList1 = [[RZArrayCollectionList alloc] initWithArray:@[@"Static Item 1", @"Static Item 2", @"Static Item 3"] sections:@[[[RZArrayCollectionListSectionInfo alloc] initWithName:@"Static 1" sectionIndexTitle:@"1" numberOfObjects:3]]];
    RZArrayCollectionList *staticList2 = [[RZArrayCollectionList alloc] initWithArray:@[@"Static Item A", @"Static Item B", @"Static Item C"] sections:@[[[RZArrayCollectionListSectionInfo alloc] initWithName:@"Static 2" sectionIndexTitle:@"2" numberOfObjects:3]]];
    self.dynamicList = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:@"subtitle"];
    RZCompositeCollectionList *compositeList = [[RZCompositeCollectionList alloc] initWithSourceLists:@[staticList1, self.dynamicList, staticList2]];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:compositeList delegate:self];
    self.dataSource.showSectionHeaders = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addButtonTapped:(id)sender
{
    static NSUInteger totalCount = 0;
    ++totalCount;
    
    if ([self.dynamicList.sections count] == 0)
    {
        [self.dynamicList addSection:[[RZArrayCollectionListSectionInfo alloc] initWithName:@"Dynamic" sectionIndexTitle:@"D" numberOfObjects:0]];
    }
    
    [self.dynamicList addObject:[ListItemObject listItemObjectWithName:[NSString stringWithFormat:@"Dynamic Item %u", totalCount] subtitle:@"Dynamic"] toSection:0];
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CompositeCellIdentifier";
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    if ([object isKindOfClass:[NSString class]])
    {
        cell.textLabel.text = object;
        cell.detailTextLabel.text = @"Static";
    }
    else if ([object isKindOfClass:[ListItemObject class]])
    {
        ListItemObject *item = (ListItemObject*)object;
        cell.textLabel.text = item.itemName;
        cell.detailTextLabel.text = item.subtitle;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 1);
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UITableViewCellEditingStyleDelete)
    {
        [self.dynamicList removeObjectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        
        if (self.dynamicList.listObjects.count == 0)
        {
            [self.dynamicList removeSectionAtIndex:0];
        }
    }
}

@end
