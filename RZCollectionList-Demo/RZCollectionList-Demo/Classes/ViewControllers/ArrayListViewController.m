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
#import "RZCollectionListCollectionViewDataSource.h"
#import "ListItemObject.h"

#define kRZCellIdentifier @"ArrayCellIdentifier"

@interface ArrayListViewController () <RZCollectionListTableViewDataSourceDelegate, RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listTableViewDataSource;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *listCollectionViewDataSource;

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
    self.arrayList.objectUpdateNotifications = @[kRZCollectionListItemUpdateNotificationName];
    
    if (self.tableView)
    {
        self.listTableViewDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.arrayList delegate:self];
        self.tableView.delegate = self;
    }
    
    if (self.collectionView)
    {
        self.listCollectionViewDataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView collectionList:self.arrayList delegate:self];
        
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kRZCellIdentifier];
        [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout setItemSize:CGSizeMake(120, 120)];
    }
    
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ListItemObject *item = [self.arrayList objectAtIndexPath:indexPath];
    
    if ([item.itemName isEqualToString:@"Item Selected"])
    {
        item.itemName = @"Item Unselected";
    }
    else
    {
        item.itemName = @"Item Selected";
    }
    
    [item commitChanges];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - RZCollectionListTableViewDataSourceDelegate

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:kRZCellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kRZCellIdentifier];
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

#pragma mark - RZCollectionListCollectionViewDataSourceDelegate

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRZCellIdentifier forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
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

@end
