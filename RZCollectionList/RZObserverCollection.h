//
//  RZObserverCollection.h
//  Rue La La
//
//  Created by Nick Donaldson on 1/2/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

// This class is intended to serve as a collection of weakly-referenced objects
// for use with observer-delegate design patterns. For iOS 6+, NSMapTable
// will serve this purpose, but for earlier versions, it is necessary to use
// associated objects.
//
// For versions less than iOS 6, the references are non-zeroing, so observers are absolutely
// responsible for removing themselves from the observer list when being deallocated,
// Otherwise messages may be sent to deallocated instances. However, it is suggested that
// observers remove themselves anyway.

#import <Foundation/Foundation.h>

@interface RZObserverCollection : NSObject

//! The observer objects in this collection.
@property (nonatomic, readonly) NSArray *allObjects;

- (void)addObject:(id)observer;
- (void)removeObject:(id)observer;

@end
