//
//  RZCollectionListTableViewDataSource.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListProtocol.h"
#import <UIKit/UITableView.h>

#pragma mark - RZCollectionListTableViewDataSourceDelegate

/**
 *  An object that adopts the RZCollectionListTableViewDataSourceDelegate protocol is responsible for providing the data and views required by an
 *  RZCollectionListTableViewDataSource instance for a UITableView. It also handles the creation and configuration of cells
 *  used by the table view to display the data in the supplied collection list.
 */
@protocol RZCollectionListTableViewDataSourceDelegate <NSObject>

@required

/**
 *  Callback to provide a cell to the data source for a particular object.
 *
 *  @param tableView The table view associated with this data source.
 *  @param object    Use this object to populate your cell.
 *  @param indexPath The index path of the object in your collection list.
 *
 *  @warning Must return a valid UITableViewCell from - (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;
 *
 *  @return A configured UITableViewCell object. You must not return nil from this method.
 */
- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

/**
 *  Implement this to immediately update a cell's contents as part of a batch update, as opposed to reloading after a batch animation.
 *
 *  @param tableView The table view associated with this data source.
 *  @param cell      The cell to be updated.
 *  @param object    The object used to populate the cell.
 *  @param indexPath The index path of the cell being updated.
 */
- (void)tableView:(UITableView *)tableView updateCell:(UITableViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 *  A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView The table view associated with this data source.
 *  @param section   The section to be associated with the provided title.
 *
 *  @return A string to be shown in the header of this section of the table view.
 */
- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;

/**
 *  A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView The table view associated with this data source.
 *  @param section   The section to be associated with the provided title.
 *
 *  @return A string to be shown in the footer of this section of the table view.
 */
- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;

/**
 * A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView The table view associated with this data source.
 *  @param object    The object used to populate the cell.
 *  @param indexPath The index path of the cell requesting this information.
 *
 *  @return A boolean to allow or disallow the editing of the cell.
 */
- (BOOL)tableView:(UITableView *)tableView canEditObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 *  A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView The table view associated with this data source.
 *  @param object    The object used to populate the cell.
 *  @param indexPath The index path of the cell requesting this information.
 *
 *  @return A boolean to allow or disallow the reordering of the cell.
 */
- (BOOL)tableView:(UITableView *)tableView canMoveObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 *  A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView    The table view associated with this data source.
 *  @param editingStyle UITableViewCellEditingStyleNone, UITableViewCellEditingStyleDelete, or UITableViewCellEditingStyleInsert
 *  @param indexPath    The index path of the cell requesting this information.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  A mirror of the UITableViewDataSource callback, use this method instead.
 *
 *  @param tableView            The table view associated with this data source.
 *  @param sourceIndexPath      The current index path for the object.
 *  @param destinationIndexPath The new index path for the object.
 */
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

#pragma mark - RZCollectionListTableViewDataSource

/**
 *  Table view data source implementation to use a collection list as the data for a UITableView.
 */
@interface RZCollectionListTableViewDataSource : NSObject <UITableViewDataSource>

/**
 *  The table view associated with this data source.
 *  @note Can only be set during initialization.
 */
@property (nonatomic, weak, readonly) UITableView *tableView;

/**
 *  The collection list used as the data source for the collection view. May safely be changed or set to nil after initialization.
 */
@property (nonatomic, strong) id<RZCollectionList> collectionList;


/**
 *  The delegate for this data source.
 */
@property (nonatomic, weak) id<RZCollectionListTableViewDataSourceDelegate> delegate;

/**
 *  Whether to show the index control on the right side of the table view.
 *  @note Defaults to NO
 */
@property (nonatomic, assign, getter = shouldShowTableIndex) BOOL showTableIndex;

/**
 *  Set this to YES to have the table view show the titles of the sections of the collection list as header views.
 *  @note Defaults to NO.
 *  @warning Overridden if the delegate implements tableView:titleForHeaderInSection:
 */
@property (nonatomic, assign, getter = shouldShowSectionHeaders) BOOL showSectionHeaders;

/**
 *  Set this to YES to have the table view animate any changes to the collection list. Otherwise, the tableview will just be reloaded.
 *  @note Defaults to YES.
 */
@property (nonatomic, assign, getter = shouldAnimateTableChanges) BOOL animateTableChanges;

/**
 *  Specify the UITableViewRowAnimation style for section additions. 
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation addSectionAnimation;

/**
 *  Specify the UITableViewRowAnimation style for section removals.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation removeSectionAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object additions.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation addObjectAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object removals.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation removeObjectAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object updates.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation updateObjectAnimation;

/**
 *  Initializer for an RZCollectionListTableViewDataSource instance.
 *
 *  @param tableView      The table view to be associated with this data source. Must not be nil.
 *  @param collectionList The collection list to be used as the data source for the table view.
 *  @param delegate       A required delegate for providing table view cells.
 *
 *  @return An instance of RZCollectionListCollectionViewDataSourceDelegate. It's usually helpful to keep this as a property.
 */
- (id)initWithTableView:(UITableView*)tableView
         collectionList:(id<RZCollectionList>)collectionList
               delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate;


/**
 *  Initializer for an RZCollectionListTableViewDataSource instance with table view index and header options.
 *
 *  @param tableView            The table view to be associated with this data source. Must not be nil.
 *  @param collectionList       The collection list to be used as the data source for the table view.
 *  @param delegate             A required delegate for providing table view cells.
 *  @param showTableIndex       If @c YES and the collection list provides section names, the table view 
 *                              will show an index control on the right side based on these names.
 *  @param showSectionHeaders   If @c YES and the collection list provides section names, the table view 
 *                              will show section headers in the default style.
 *
 *  @return An instance of RZCollectionListCollectionViewDataSourceDelegate. It's usually helpful to keep this as a property.
 */
- (id)initWithTableView:(UITableView*)tableView
         collectionList:(id<RZCollectionList>)collectionList
               delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
         showTableIndex:(BOOL)showTableIndex
     showSectionHeaders:(BOOL)showSectionHeaders;

#pragma mark - TableViewAnimations

/**
 *  Set the animation style for all section and object changes in your collection list associated with this data source.
 *
 *  @param animation UITableViewRowAnimation style.
 */
- (void)setAllAnimations:(UITableViewRowAnimation)animation;

/**
 *  Set the animation style for all section changes in your collection list associated with this data source.
 *
 *  @param animation UITableViewRowAnimation style.
 */
- (void)setAllSectionAnimations:(UITableViewRowAnimation)animation;

/**
 *  Set the animation style for all object changes in your collection list associated with this data source.
 *
 *  @param animation UITableViewRowAnimation style.
 */
- (void)setAllObjectAnimations:(UITableViewRowAnimation)animation;

@end
