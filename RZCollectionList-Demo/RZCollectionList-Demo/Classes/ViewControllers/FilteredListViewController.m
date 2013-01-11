//
//  FilteredListViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "FilteredListViewController.h"
#import "RZArrayCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"
#import "RZCollectionListCollectionViewDataSource.h"
#import "ListItemObject.h"

#define kRZCellIdentifier @"FilteredCellIdentifier"

@interface FilteredListViewController () <RZCollectionListTableViewDataSourceDelegate, RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RZFilteredCollectionList *filteredList;
@property (nonatomic, strong) RZCollectionListTableViewDataSource *listTableViewDataSource;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *listCollectionViewDataSource;

- (NSArray*)listItemObjects;

- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

@end

@implementation FilteredListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
        self.navigationItem.rightBarButtonItem = searchItem;
    }
    
    RZArrayCollectionList *arrayList = [[RZArrayCollectionList alloc] initWithArray:[self listItemObjects] sectionNameKeyPath:nil];
    self.filteredList = [[RZFilteredCollectionList alloc] initWithSourceList:arrayList predicate:nil];
    
    if (self.tableView)
    {
        self.listTableViewDataSource = [[RZCollectionListTableViewDataSource alloc] initWithTableView:self.tableView collectionList:self.filteredList delegate:self];
    }
    
    if (self.collectionView)
    {
        self.listCollectionViewDataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView collectionList:self.filteredList delegate:self];
        
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kRZCellIdentifier];
        [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout setItemSize:CGSizeMake(120, 120)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (NSArray*)listItemObjects
{
    NSUInteger numItems = 100;
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:numItems];
    
    for (int i=0; i < numItems; ++i)
    {
        NSString *itemName = [NSString stringWithFormat:@"Item %d", i];
        NSString *itemSubtitle = [NSString stringWithFormat:@"%d Subtitle", i / 6];
        [items addObject:[ListItemObject listItemObjectWithName:itemName subtitle:itemSubtitle]];
    }
    
    return items;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - RZCollectionListDataSourceDelegate

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

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSPredicate * predicate = nil;
    
    if (searchText && [searchText length] > 0)
    {
        predicate = [NSPredicate predicateWithFormat:@"itemName CONTAINS %@", searchText];
    }
    
    self.filteredList.predicate = predicate;
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

#pragma mark - UIKeyboard Notification Callbacks

- (void)keyboardWillShow:(NSNotification*)notification
{
    NSTimeInterval keyboardAnimTime = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.bottomSpaceConstraint.constant = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)? -keyboardFrame.size.width : -keyboardFrame.size.height;
    
    [UIView animateWithDuration:keyboardAnimTime delay:0 options:keyboardAnimCurve animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    NSTimeInterval keyboardAnimTime = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve keyboardAnimCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    self.bottomSpaceConstraint.constant = 0;
    
    [UIView animateWithDuration:keyboardAnimTime delay:0 options:keyboardAnimCurve animations:^{
        [self.view layoutIfNeeded];
    } completion:NULL];
}

@end
