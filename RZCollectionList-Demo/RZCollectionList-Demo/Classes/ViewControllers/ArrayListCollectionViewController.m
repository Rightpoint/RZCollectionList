//
//  ArrayListCollectionViewController.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "ArrayListCollectionViewController.h"
#import "RZArrayCollectionList.h"
#import "RZCollectionListCollectionViewDataSource.h"
#import "ListItemObject.h"

#define kRZCollectionCellIdentifier @"RZCollectionCellIdentifier"

@interface ArrayListCollectionViewController () <RZCollectionListCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RZArrayCollectionList *arrayList;
@property (nonatomic, strong) RZCollectionListCollectionViewDataSource *listDataSource;

@end

@implementation ArrayListCollectionViewController

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
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kRZCollectionCellIdentifier];
    [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout setItemSize:CGSizeMake(100, 100)];
    
    self.arrayList = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:nil];
    self.listDataSource = [[RZCollectionListCollectionViewDataSource alloc] initWithCollectionView:self.collectionView collectionList:self.arrayList delegate:self];
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

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kRZCollectionCellIdentifier forIndexPath:indexPath];
    
    ListItemObject *item = (ListItemObject*)object;
    
    if ([item isKindOfClass:[ListItemObject class]])
    {
        CGSize itemSize = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize;
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, itemSize.width, itemSize.height/2)];
        UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, itemSize.height/2, itemSize.width, itemSize.height/2)];
        
        nameLabel.text = item.itemName;
        detailLabel.text = item.subtitle;
        
        [cell.contentView addSubview:nameLabel];
        [cell.contentView addSubview:detailLabel];
    }
    
    return cell;
}

@end
