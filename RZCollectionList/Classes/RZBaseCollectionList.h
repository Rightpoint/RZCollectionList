//
//  RZBaseCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"

/***************************************************************
 *
 * Base class for providing common variables and
 * utils for RZCollectionList "source" lists, i.e.
 * lists that maintain/represent a concrete collection
 * of objects, rather than a "modified" collection.
 * 
 * Currently used as subclass for RZFetchedCollectionList
 * and RZArrayCollectionList.
 *
 * This class implements the protocol but requires subclasses
 * to override the protocol methods, or an exception will be
 * thrown.
 *
 ****************************************************************/

@interface RZBaseCollectionList : NSObject <RZCollectionList>

@end