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
#import "RZCollectionListCollectionViewDataSource.h"
#import "ListItemObject.h"

#define kRZCellIdentifier @"SortedCellIdentifier"

@interface SortedListViewController () <RZCollectionListTableViewDataSourceDelegate, RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RZSortedCollectionList *sortedList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listTableViewDataSource;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *listCollectionViewDataSource;

- (NSArray*)listItemObjects;

- (NSArray*)sortDescriptorsForSegmentValue:(NSUInteger)segmentValue;

@end

@implementation SortedListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if ( [self respondsToSelector:@selector(setEdgesForExtendedLayout:)] ) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:self.sortSegmentControl];
        self.navigationItem.rightBarButtonItems = @[segmentItem, self.makeMiddleNegativeBarButtonItem];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = self.makeMiddleNegativeBarButtonItem;
    }
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:[self listItemObjects] sectionNameKeyPath:@"subtitle"];
    arrayList.objectUpdateNotifications = @[kRZCollectionListItemUpdateNotificationName];
    NSArray *sortDescriptors = [self sortDescriptorsForSegmentValue:self.sortSegmentControl.selectedSegmentIndex];
    self.sortedList = [[RZSortedCollectionList alloc] initWithSourceList:arrayList sortDescriptors:sortDescriptors];
    
    if (self.tableView)
    {
        self.listTableViewDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.sortedList delegate:self];
    }
    
    if (self.collectionView)
    {
        self.listCollectionViewDataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView collectionList:self.sortedList delegate:self];
        
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kRZCellIdentifier];
        [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout setItemSize:CGSizeMake(120, 120)];
    }
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

#pragma mark - RZCollectionListCollectionViewDataSourceDelegate

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRZCellIdentifier forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];
    
    ListItemObject *item = (ListItemObject*)object;
    
    if ([item isKindOfClass:[ListItemObject class]])
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

#pragma mark - Action Methods

- (IBAction)sortSegmentControlChanged:(id)sender
{
    NSUInteger segmentIndex = self.sortSegmentControl.selectedSegmentIndex;
    NSArray *sortDescriptors = [self sortDescriptorsForSegmentValue:segmentIndex];
    self.sortedList.sortDescriptors = sortDescriptors;
}

- (IBAction)makeMiddleNegativeButtonTapped:(id)sender
{
    static BOOL isNegative = NO;
    static NSString *lastName = nil;
    
    ListItemObject *lastObject = [self.sortedList.sourceList.listObjects lastObject];

    if (lastName == nil)
    {
        lastName = lastObject.itemName;
    }
    
    if (isNegative)
    {
        lastObject.itemName = lastName;
    }
    else
    {
        lastObject.itemName = @"Item -1";
    }
    
    [lastObject commitChanges];
    
    isNegative = !isNegative;
}
@end
