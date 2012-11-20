//
//  DemoCollectionListViewController.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RZCollectionListTableViewDataSource;

@interface DemoCollectionListViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) RZCollectionListTableViewDataSource *dataSource;
@property (strong, nonatomic) NSManagedObjectContext *moc;

@end
