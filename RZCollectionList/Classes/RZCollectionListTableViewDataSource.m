//
//  RZCollectionListTableViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListTableViewDataSource.h"

#import <QuartzCore/QuartzCore.h>

@interface RZCollectionListTableViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, weak, readwrite) UITableView *tableView;

@property (nonatomic, assign) BOOL delegateImplementsInPlaceUpdate;
@property (nonatomic, assign) BOOL reloadAfterAnimation;
@property (nonatomic, assign) BOOL tableViewBeginUpdatesWasCalled;

@end

@implementation RZCollectionListTableViewDataSource

- (id)initWithTableView:(UITableView*)tableView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
{
    return [self initWithTableView:tableView collectionList:collectionList delegate:delegate showTableIndex:NO showSectionHeaders:NO];
}

- (id)initWithTableView:(UITableView*)tableView
         collectionList:(id<RZCollectionList>)collectionList
               delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
         showTableIndex:(BOOL)showTableIndex
     showSectionHeaders:(BOOL)showSectionHeaders
{
    NSParameterAssert(tableView);

    self = [super init];
    if ( self != nil ) {
        self.delegate = delegate;
        self.tableView = tableView;
        _showTableIndex = showTableIndex;
        _showSectionHeaders = showSectionHeaders;

        
        self.animateTableChanges = YES;
        [self setAllAnimations:UITableViewRowAnimationFade];
        
        tableView.dataSource = self;
        
        self.collectionList = collectionList;
    }
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self];
}

- (void)setCollectionList:(id<RZCollectionList>)collectionList
{
    if (collectionList != _collectionList)
    {
        if (nil != _collectionList)
        {
            [_collectionList removeCollectionListObserver:self];
            _collectionList.delegate = nil;
        }
        
        _collectionList = collectionList;
        
        if (nil != collectionList)
        {
            [collectionList addCollectionListObserver:self];
            collectionList.delegate = self;
        }
        
        [self.tableView reloadData];
    }
}

- (void)setDelegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
{
    _delegate = delegate;
    self.delegateImplementsInPlaceUpdate = [delegate respondsToSelector:@selector(tableView:updateCell:forObject:atIndexPath:)];
}

- (void)setAllAnimations:(UITableViewRowAnimation)animation
{
    [self setAllSectionAnimations:animation];
    [self setAllObjectAnimations:animation];
}

- (void)setAllSectionAnimations:(UITableViewRowAnimation)animation
{
    self.addSectionAnimation = animation;
    self.removeSectionAnimation = animation;
}

- (void)setAllObjectAnimations:(UITableViewRowAnimation)animation
{
    self.addObjectAnimation = animation;
    self.removeObjectAnimation = animation;
    self.updateObjectAnimation = animation;
}

- (void)setShowTableIndex:(BOOL)showTableIndex
{
    if ( _showTableIndex != showTableIndex ) {
        _showTableIndex = showTableIndex;
        [self.tableView reloadData];
    }
}

- (void)setShowSectionHeaders:(BOOL)showSectionHeaders
{
    if ( _showSectionHeaders != showSectionHeaders ) {
        _showSectionHeaders = showSectionHeaders;
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<RZCollectionListSectionInfo> sectionInfo = [self.collectionList.sections objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.collectionList objectAtIndexPath:indexPath];
    return [self.delegate tableView:tableView cellForObject:object atIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.collectionList.sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
    {
        sectionTitle = [self.delegate tableView:tableView titleForHeaderInSection:section];
    }
    else if (self.showSectionHeaders)
    {
        id<RZCollectionListSectionInfo> sectionInfo = [self.collectionList.sections objectAtIndex:section];
        sectionTitle = sectionInfo.name;
    }
    
    return sectionTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:titleForFooterInSection:)])
    {
        sectionTitle = [self.delegate tableView:tableView titleForFooterInSection:section];
    }
    
    return sectionTitle;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canEdit = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:canEditObject:atIndexPath:)])
    {
        id object = [self.collectionList objectAtIndexPath:indexPath];
        canEdit = [self.delegate tableView:tableView canEditObject:object atIndexPath:indexPath];
    }
    
    return canEdit;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canMove = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:canMoveObject:atIndexPath:)])
    {
        id object = [self.collectionList objectAtIndexPath:indexPath];
        canMove = [self.delegate tableView:tableView canMoveObject:object atIndexPath:indexPath];
    }
    
    return canMove;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView;
{
    NSArray *sectionIndexTitles = nil;
    
    if (self.showTableIndex)
    {
        sectionIndexTitles = [self.collectionList sectionIndexTitles];
    }
    
    return sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.collectionList sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)])
    {
        [self.delegate tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
    }
    // TODO: Modify the collectionList
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)])
    {
        [self.delegate tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
    // TODO: Modify the collectionList
}

#pragma mark - RZCollectionListDelegate

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    // Animating changes when the tableView is offscreen will produce a crash
    if (self.animateTableChanges  && self.tableView.window != nil)
    {
        switch(type) {
            case RZCollectionListChangeInsert:
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:self.addObjectAnimation];
                break;
            case RZCollectionListChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:self.removeObjectAnimation];
                break;
            case RZCollectionListChangeMove:
                [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
                break;
            case RZCollectionListChangeUpdate:
            {                
                // is this row visible? If so we need to update this cell.
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell != nil)
                {
                    
                    // If the delegate implements the update method, update right now. Otherwise delay.
                    if (self.delegateImplementsInPlaceUpdate)
                    {
                        [self.delegate tableView:self.tableView updateCell:cell forObject:object atIndexPath:newIndexPath];
                    }
                    else
                    {
                        self.reloadAfterAnimation = YES;
                    }
                }
            }
                break;
            default:
                //uncaught type
                NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
                break;
        }
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    // Animating changes when the tableView is offscreen produce a crash
    if (self.animateTableChanges  && self.tableView.window != nil)
    {
        switch(type) {
            case RZCollectionListChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:self.addSectionAnimation];
                break;
                
            case RZCollectionListChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:self.removeSectionAnimation];
                break;
                
            default:
                //uncaught type
                NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
                break;
        }
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    // Checks to animation and window are made here to prevent unbalanced calls to begin/end updates
    if (self.animateTableChanges && self.tableView.window != nil)
    {
        [self.tableView beginUpdates];
        self.tableViewBeginUpdatesWasCalled = YES;
    }
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    // Animating changes when the tableView is offscreen produce a crash
    if (self.animateTableChanges && self.tableView.window != nil && self.tableViewBeginUpdatesWasCalled )
    {
        self.tableViewBeginUpdatesWasCalled = NO;
        
        if (self.reloadAfterAnimation)
        {
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [self.tableView reloadData];
            }];
        }
        
        [self.tableView endUpdates];
        
        if (self.reloadAfterAnimation)
        {
            [CATransaction commit];
            self.reloadAfterAnimation = NO;
        }
    }
    else
    {
        [self.tableView reloadData];
    }
}

- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName
{
    return nil;
}

@end
