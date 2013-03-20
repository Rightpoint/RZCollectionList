//
//  SortedListViewController.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/4/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SortedListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortSegmentControl;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *makeMiddleNegativeBarButtonItem;

- (IBAction)sortSegmentControlChanged:(id)sender;
- (IBAction)makeMiddleNegativeButtonTapped:(id)sender;
@end
