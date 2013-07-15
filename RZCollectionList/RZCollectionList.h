//
//  RZCollectionList.h
//  RZCollectionList
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

/************************************************************
 *
 *  Include this file to get all the collection lists at once
 *
 ************************************************************/

#import "RZArrayCollectionList.h"
#import "RZFetchedCollectionList.h"
#import "RZFilteredCollectionList.h"
#import "RZSortedCollectionList.h"
#import "RZCompositeCollectionList.h"
#import "RZCollectionListTableViewDataSource.h"

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0)
    #import "RZCollectionListCollectionViewDataSource.h"
#endif

// Category for helping construct fetch requests
#import "NSFetchRequest+RZCreationHelpers.h"