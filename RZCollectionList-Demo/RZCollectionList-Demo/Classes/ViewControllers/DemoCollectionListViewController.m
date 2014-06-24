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
#import "SortedListViewController.h"
#import "CompositeListViewController.h"


NSString * const kArrayCollectionList =  @"ArrayCollectionList";
NSString * const kFetchedCollectionListManual = @"FetchedCollectionList - Manual";
NSString * const kFetchedCollectionListAuto = @"FetchedCollectionList - Auto";
NSString * const kFilteredCollectionList =  @"FilteredCollectionList";
NSString * const kSortedCollectionList =  @"SortedCollectionList";
NSString * const kCompositeCollectionList =  @"CompositeCollectionList";
NSString * const kArrayListCollectionView =  @"ArrayList - Collection View";

@interface DemoCollectionListViewController () <RZCollectionListTableViewDataSourceDelegate, UITableViewDelegate>

@end

@implementation DemoCollectionListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"RZCollectionList Demo";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:NULL];
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:@[kArrayCollectionList, kFetchedCollectionListManual, kFetchedCollectionListAuto, kFilteredCollectionList, kSortedCollectionList, kCompositeCollectionList, kArrayListCollectionView]  sectionNameKeyPath:nil];
    
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
    
    UIViewController *listController = nil;
    
    if (kArrayCollectionList == demoClass)
    {
        ArrayListViewController *arrayVC = [[ArrayListViewController alloc] init];
        arrayVC.title = @"Array List";
        
        listController = arrayVC;
    }
    else if (kFetchedCollectionListManual == demoClass)
    {
        FetchedListViewController *fetchVC = [[FetchedListViewController alloc] init];
        fetchVC.title = @"Fetched List Manual";
        fetchVC.moc = self.moc;
        
        listController = fetchVC;
    }
    else if (kFetchedCollectionListAuto == demoClass)
    {
        FetchedListViewController *fetchVC = [[FetchedListViewController alloc] init];
        fetchVC.title = @"Fetched List Auto";
        fetchVC.moc = self.moc;
        fetchVC.autoAddRemove = YES;
        
        listController = fetchVC;
    }
    else if (kFilteredCollectionList == demoClass)
    {
        FilteredListViewController *filteredVC = [[FilteredListViewController alloc] init];
        filteredVC.title = @"Filtered List";
        
        listController = filteredVC;
    }
    else if (kSortedCollectionList == demoClass)
    {
        SortedListViewController *sortedVC = [[SortedListViewController alloc] init];
        sortedVC.title = @"Sorted List";
        
        listController = sortedVC;
    }
    else if (kCompositeCollectionList == demoClass)
    {
        CompositeListViewController *compositeVC = [[CompositeListViewController alloc] init];
        compositeVC.title = @"Composite List";
        
        listController = compositeVC;
    }
    else if (kArrayListCollectionView == demoClass)
    {
        ArrayListViewController *arrayCollectionVC = [[ArrayListViewController alloc] initWithNibName:@"ArrayListViewController~ipad" bundle:nil];
        arrayCollectionVC.title = @"Array List Collection View";
        
        listController = arrayCollectionVC;
    }
    
    if ( listController != nil )
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            UINavigationController *navController = (UINavigationController*)[self.splitViewController.viewControllers lastObject];
            [navController setViewControllers:@[listController] animated:NO];
        }
        else
        {
            [self.navigationController pushViewController:listController animated:YES];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
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
