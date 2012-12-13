//
//  ArrayListCollectionViewController.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 12/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArrayListCollectionViewController : UIViewController
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addItemBarButton;

- (IBAction)addNewItemTapped:(id)sender;

@end
