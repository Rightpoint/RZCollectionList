//
//  ArrayListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "ArrayListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ListItemObject.h"

@interface ArrayListViewController () <RZCollectionListTableViewDataSourceDelegate>

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listDataSource;

@end

@implementation ArrayListViewController

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
    self.navigationItem.rightBarButtonItem = self.addItemBarButton;
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:nil];
    self.listDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.arrayList delegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addNewItemTapped:(id)sender
{
    static NSUInteger totalCount = 0;
    ++totalCount;
    [self.arrayList addObject:[ListItemObject listItemObjectWithName:[NSString stringWithFormat:@"Item %u", totalCount] subtitle:nil] toSection:0];
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ArrayCellIdentifier";
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

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (UITableViewCellEditingStyleDelete)
    {
        [self.arrayList removeObjectAtIndexPath:indexPath];
    }
}

@end
