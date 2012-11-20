//
//  DemoCollectionListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "DemoCollectionListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "ArrayListViewController.h"
#import "FetchedListViewController.h"
#import "FilteredListViewController.h"



NSString * const kArrayCollectionList =  @"ArrayCollectionList";
NSString * const kFetchedCollectionListManual = @"FetchedCollectionList - Manual";
NSString * const kFetchedCollectionListAuto = @"FetchedCollectionList - Auto";
NSString * const kFilteredCollectionList =  @"FilteredCollectionList";

@interface DemoCollectionListViewController () <RZCollectionListDataSourceDelegate, UITableViewDelegate>

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
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:@[kArrayCollectionList, kFetchedCollectionListManual, kFetchedCollectionListAuto, kFilteredCollectionList]  sectionNameKeyPath:nil];
    
    self.dataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:arrayList delegate:self];
    
    self.tableView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *demoClass = [self.dataSource.collectionList objectAtIndexPath:indexPath];
    
    if (kArrayCollectionList == demoClass)
    {
        ArrayListViewController *arrayVC = [[ArrayListViewController alloc] init];
        arrayVC.title = @"Array List";
        
        [self.navigationController pushViewController:arrayVC animated:YES];
    }
    else if (kFetchedCollectionListManual == demoClass)
    {
        FetchedListViewController *fetchVC = [[FetchedListViewController alloc] init];
        fetchVC.title = @"Fetched List Manual";
        fetchVC.moc = self.moc;
        
        [self.navigationController pushViewController:fetchVC animated:YES];
    }
    else if (kFetchedCollectionListAuto == demoClass)
    {
        FetchedListViewController *fetchVC = [[FetchedListViewController alloc] init];
        fetchVC.title = @"Fetched List Auto";
        fetchVC.moc = self.moc;
        fetchVC.autoAddRemove = YES;
        
        [self.navigationController pushViewController:fetchVC animated:YES];
    }
    else if (kFilteredCollectionList == demoClass)
    {
        FilteredListViewController *filteredVC = [[FilteredListViewController alloc] init];
        filteredVC.title = @"Filtered List";
        
        [self.navigationController pushViewController:filteredVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    cell.textLabel.text = object;
    
    return cell;
}

@end
