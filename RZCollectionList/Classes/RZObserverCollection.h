//
//  RZObserverCollection.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 1/2/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  This class is intended to serve as a collection of weakly-referenced objects
 *  for use with observer-delegate design patterns. For iOS 6+, NSMapTable
 *  will serve this purpose, but for earlier versions, it is necessary to use
 *  associated objects.
 *
 *  For versions less than iOS 6, the references are non-zeroing, so observers are absolutely
 *  responsible for removing themselves from the observer list when being deallocated,
 *  Otherwise messages may be sent to deallocated instances. However, it is suggested that
 *  observers remove themselves anyway.
 */
@interface RZObserverCollection : NSObject

/**
*  The observer objects in this collection.
*/
@property (nonatomic, readonly) NSArray *allObjects;

/**
 *  Add an observer that conforms to RZCollectionListObserver protocol.
 *
 *  @param observer An observer that conforms to RZCollectionListObserver protocol.
 */
- (void)addObject:(id)observer;

/**
 *  Remove an observer.
 *
 *  @param observer An observer that conforms to RZCollectionListObserver protocol.
 */
- (void)removeObject:(id)observer;

@end
