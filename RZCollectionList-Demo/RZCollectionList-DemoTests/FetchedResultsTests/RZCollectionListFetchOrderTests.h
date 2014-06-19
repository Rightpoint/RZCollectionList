//
//  RZCollectionListFetchOrderTests.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/20/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

/*********************************************************
 *
 *  This is a test case to determine the order in which
 *  NSFetchedResultsController outputs its delegate notifications.
 *
 *********************************************************/

#import <XCTest/XCTest.h>
#import "RZCollectionListTestsBase.h"

@interface RZCollectionListFetchOrderTests : RZCollectionListTestsBase  <NSFetchedResultsControllerDelegate>

@end
