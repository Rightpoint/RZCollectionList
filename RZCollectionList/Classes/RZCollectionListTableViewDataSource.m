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

@property (nonatomic, strong, readwrite) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *updatedIndexPaths;

@end

@implementation RZCollectionListTableViewDataSource

- (id)initWithTableView:(UITableView*)tableView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListTableViewDataSourceDelegate>)delegate
{
    if ((self = [super init]))
    {
        self.collectionList = collectionList;
        self.delegate = delegate;
        self.tableView = tableView;

        [self.collectionList addCollectionListObserver:self];
        
        self.animateTableChanges = YES;
        [self setAllAnimations:UITableViewRowAnimationFade];
        collectionList.delegate = self;
        
        tableView.dataSource = self;
        
        // reload data here to prep for collection list observations
        [tableView reloadData];
        
        self.updatedIndexPaths = [NSMutableArray arrayWithCapacity:16];
    }
    
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self];
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
    BOOL canEdit = YES;
    
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
    if (self.animateTableChanges)
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
                if (cell != nil){
                    
                    // If the delegate implements the update method, update right now. Otherwise delay.
                    if ([self.delegate respondsToSelector:@selector(tableView:updateCell:forObject:atIndexPath:)]){
                        [self.delegate tableView:self.tableView updateCell:cell forObject:object atIndexPath:newIndexPath];
                    }
                    else{
                        [self.updatedIndexPaths addObject:newIndexPath];
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
    if (self.animateTableChanges)
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
    if (self.animateTableChanges)
    {
        [self.tableView beginUpdates];
    }
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    if (self.animateTableChanges)
    {
        [self.tableView endUpdates];
        
        // delay update notifications
        if (self.updatedIndexPaths.count > 0){
            
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:self.updatedIndexPaths withRowAnimation:self.updateObjectAnimation];
            [self.tableView endUpdates];
            
            [self.updatedIndexPaths removeAllObjects];
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
