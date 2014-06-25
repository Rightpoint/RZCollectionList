//
//  RZCollectionListTableViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"

@protocol RZCollectionListTableViewDataSourceDelegate <NSObject>

@required
- (UITableViewCell*)tableView:(UITableView*)tableView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

//! Implement this to immediately update a cell's contents as part of a batch update, as opposed to reloading after the animations complete
/*!
    The indexPath parameter is the index path of the object in the collection list at the time this method is called, NOT the index path of the cell being updated!
 */
- (void)tableView:(UITableView*)tableView updateCell:(UITableViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;

- (BOOL)tableView:(UITableView*)tableView canEditObject:(id)object atIndexPath:(NSIndexPath*)indexPath;
- (BOOL)tableView:(UITableView*)tableView canMoveObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@interface RZCollectionListTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, strong, readonly) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readonly) UITableView *tableView;

@property (nonatomic, weak) id<RZCollectionListTableViewDataSourceDelegate> delegate;

@property (nonatomic, assign, getter = shouldShowTableIndex) BOOL showTableIndex;                           // Defaults to NO
@property (nonatomic, assign, getter = shouldShowSectionHeaders) BOOL showSectionHeaders;                   // Defaults to NO, Overridden if the delegate implements tableView:titleForHeaderInSection:
@property (nonatomic, assign, getter = shouldAnimateTableChanges) BOOL animateTableChanges;                 // Defaults to YES

@property (nonatomic, assign) UITableViewRowAnimation addSectionAnimation;      // Defaults to UITableViewRowAnimationFade
@property (nonatomic, assign) UITableViewRowAnimation removeSectionAnimation;   // Defaults to UITableViewRowAnimationFade
@property (nonatomic, assign) UITableViewRowAnimation addObjectAnimation;       // Defaults to UITableViewRowAnimationFade
@property (nonatomic, assign) UITableViewRowAnimation removeObjectAnimation;    // Defaults to UITableViewRowAnimationFade
@property (nonatomic, assign) UITableViewRowAnimation updateObjectAnimation;    // Defaults to UITableViewRowAnimationFade

- (id)initWithTableView:(UITableView*)tableView
         collectionList:(id<RZCollectionList>)collectionList
               delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
         showTableIndex:(BOOL)showTableIndex
     showSectionHeaders:(BOOL)showSectionHeaders;

- (id)initWithTableView:(UITableView*)tableView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate;

// TableViewAnimations
- (void)setAllAnimations:(UITableViewRowAnimation)animation;
- (void)setAllSectionAnimations:(UITableViewRowAnimation)animation;
- (void)setAllObjectAnimations:(UITableViewRowAnimation)animation;

@end
