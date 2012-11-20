//
//  RZCollectionListTableViewDataSource.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/14/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "RZCollectionListTableViewDataSource.h"

@interface RZCollectionListTableViewDataSource () <RZCollectionListDelegate, RZCollectionListObserver>

@property (nonatomic, strong, readwrite) id<RZCollectionList> collectionList;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@end

@implementation RZCollectionListTableViewDataSource

- (id)initWithTableView:(UITableView*)tableView collectionList:(id<RZCollectionList>)collectionList delegate:(id<RZCollectionListDataSourceDelegate>)delegate
{
    if ((self = [super init]))
    {
        self.collectionList = collectionList;
        self.delegate = delegate;
        self.tableView = tableView;
        
        [collectionList addCollectionListObserver:self];
        collectionList.delegate = self;
        
        tableView.dataSource = self;
    }
    
    return self;
}

- (void)dealloc
{
    [self.collectionList removeCollectionListObserver:self];
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
    // TODO: Modify the collectionList
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // TODO: Modify the collectionList
}

#pragma mark - RZCollectionListDelegate

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeObject:(id)object atIndexPath:(NSIndexPath*)indexPath forChangeType:(RZCollectionListChangeType)type newIndexPath:(NSIndexPath*)newIndexPath
{
    switch(type) {
        case RZCollectionListChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case RZCollectionListChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case RZCollectionListChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case RZCollectionListChangeUpdate:
        {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
        default:
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)collectionList:(id<RZCollectionList>)collectionList didChangeSection:(id<RZCollectionListSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(RZCollectionListChangeType)type
{
    switch(type) {
        case RZCollectionListChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case RZCollectionListChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            //uncaught type
            NSLog(@"We got to the default switch statement we should not have gotten to. The Change Type is: %d", type);
            break;
    }
}

- (void)collectionListWillChangeContent:(id<RZCollectionList>)collectionList
{
    [self.tableView beginUpdates];
}

- (void)collectionListDidChangeContent:(id<RZCollectionList>)collectionList
{
    [self.tableView endUpdates];
}

- (NSString *)collectionList:(id<RZCollectionList>)collectionList sectionIndexTitleForSectionName:(NSString *)sectionName
{
    return nil;
}

@end
