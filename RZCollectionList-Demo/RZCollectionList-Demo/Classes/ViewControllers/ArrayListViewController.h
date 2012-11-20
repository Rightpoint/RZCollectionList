//
//  ArrayListViewController.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArrayListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addItemBarButton;

- (IBAction)addNewItemTapped:(id)sender;
@end
