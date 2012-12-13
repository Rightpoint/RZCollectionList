//
//  FetchedListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "FetchedListViewController.h"
#import "RZFetchedCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "NSFetchRequest+RZCreationHelpers.h"
#import "ListItem.h"

@interface FetchedListViewController () <RZCollectionListTableViewDataSourceDelegate>

@property (nonatomic, strong) RZFetchedCollectionList *fetchedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listDataSource;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSUInteger totalCount;

- (void)autoChangeDataModel;

@end

@implementation FetchedListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.totalCount = 0;
    }
    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.rightBarButtonItem = self.addItemBarButton;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ListItem" sortDescriptorKey:@"itemName" ascending:YES];
    self.fetchedList = [[RZFetchedCollectionList alloc] initWithFetchRequest:request
                                                                            managedObjectContext:self.moc
                                                                              sectionNameKeyPath:@"subtitle"
                                                                                       cacheName:nil];
    
    self.listDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.fetchedList delegate:self];
    
    self.totalCount = [self.fetchedList.listObjects count];
    
    if (self.autoAddRemove)
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(autoChangeDataModel) userInfo:nil repeats:YES];
        self.addItemBarButton.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)autoChangeDataModel
{
    static BOOL ascending = YES;
    
    if (self.fetchedList.listObjects.count <= 0)
    {
        ascending = YES;
    }
    else if (self.fetchedList.listObjects.count >= 24)
    {
        ascending = NO;
    }
    
    
    if (ascending)
    {
        ListItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.moc];
        item.itemName = [NSString stringWithFormat:@"Count: %d", self.totalCount];
        item.subtitle = [NSString stringWithFormat:@"%d Subtitle", self.fetchedList.listObjects.count / 3];
        
        self.totalCount += 1;
    }
    else
    {
        ListItem *item = [self.fetchedList.listObjects lastObject];
        
        [self.moc deleteObject:item];
    }
    
    
    [self.moc save:nil];
}

- (IBAction)addItemTapped:(id)sender
{
    ListItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"ListItem" inManagedObjectContext:self.moc];
    item.itemName = [NSString stringWithFormat:@"Count: %d", self.totalCount];
    item.subtitle = [NSString stringWithFormat:@"%d Subtitle", self.fetchedList.listObjects.count / 3];
    
    self.totalCount += 1;
}

#pragma mark - RZCollectionListDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"FetchedCellIdentifier";
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    ListItem *item = (ListItem*)object;
    
    if ([item isKindOfClass:[ListItem class]])
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
        ListItem *item = [self.fetchedList objectAtIndexPath:indexPath];
        
        [self.moc deleteObject:item];
        
        [self.moc save:nil];
    }
}

@end
