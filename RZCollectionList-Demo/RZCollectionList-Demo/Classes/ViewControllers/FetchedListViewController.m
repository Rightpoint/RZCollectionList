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
#import "RZCollectionListCollectionViewDataSource.h"
#import "NSFetchRequest+RZCreationHelpers.h"
#import "ListItem.h"

#define kRZCellIdentifier @"FetchedCellIdentifier"

@interface FetchedListViewController () <RZCollectionListTableViewDataSourceDelegate, RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RZFetchedCollectionList *fetchedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listTableViewDataSource;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *listCollectionViewDataSource;

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
    
    if (self.tableView)
    {
        self.listTableViewDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.fetchedList delegate:self];
    }
    
    if (self.collectionView)
    {
        self.listCollectionViewDataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView collectionList:self.fetchedList delegate:self];
        
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kRZCellIdentifier];
        [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout setItemSize:CGSizeMake(120, 120)];
    }
    
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
        item.itemName = [NSString stringWithFormat:@"Count: %lu", (unsigned long)self.totalCount];
        item.subtitle = [NSString stringWithFormat:@"%lu Subtitle", (unsigned long)self.fetchedList.listObjects.count / 3];
        
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
    item.itemName = [NSString stringWithFormat:@"Count: %lu", (unsigned long)self.totalCount];
    item.subtitle = [NSString stringWithFormat:@"%lu Subtitle", (unsigned long)self.fetchedList.listObjects.count / 3];
    
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

#pragma mark - RZCollectionListCollectionViewDataSourceDelegate

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRZCellIdentifier forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];

    ListItem *item = (ListItem*)object;
    
    if ([item isKindOfClass:[ListItem class]])
    {
        CGSize itemSize = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, itemSize.width, itemSize.height/2)];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        titleLabel.text = item.itemName;
        
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, itemSize.height/2, itemSize.width, itemSize.height/2)];
        detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
        detailLabel.text = item.subtitle;
        
        [cell.contentView addSubview:titleLabel];
        [cell.contentView addSubview:detailLabel];
    }
    
    return cell;
}

@end
