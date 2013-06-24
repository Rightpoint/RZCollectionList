//
//  RZBaseCollectionList.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/21/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZCollectionListProtocol.h"

/**************************************************
 *
 * Base classes for providing common variables and
 * utils for RZCollectionList protocol adopters.
 * 
 * These classes do not implement the protocol itself.
 *
 **************************************************/

//! This base class provides containers and methods for managing observers and sending will/did change notifications.
@interface RZBaseCollectionList : NSObject

@end

//! This base class should be used when a collection list needs to cache notifications during an udpate
@interface RZBaseNotificationCachingCollectionList : RZBaseCollectionList

@end