//
//  FetchedListViewController.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 11/20/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FetchedListViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addItemBarButton;

@property (strong, nonatomic) NSManagedObjectContext *moc;
@property (assign, nonatomic) BOOL autoAddRemove;

- (IBAction)addItemTapped:(id)sender;
@end
