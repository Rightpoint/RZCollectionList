//
//  RZObserverCollection.m
//  Rue La La
//
//  Created by Nick Donaldson on 1/2/13.
//  Copyright (c) 2013 Raizlabs Corporation. All rights reserved.
//

#define RZOCL_POINTER_ARRAY_AVAILABLE (__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_6_0)

#import "RZObserverCollection.h"

#if !RZOCL_POINTER_ARRAY_AVAILABLE
#import <objc/runtime.h>
#endif

@interface RZObserverCollection ()

#if RZOCL_POINTER_ARRAY_AVAILABLE

@property (nonatomic, strong) NSPointerArray* observerPointerArray;
- (NSUInteger)indexOfObserverInPointerArray:(id)observer;

#else

// Memory addresses of associated objects, serving as keys
@property (nonatomic, strong) NSMutableSet* observerAddresses;

#endif

@end

@implementation RZObserverCollection

- (id)init
{
    self = [super init];
    if (self){
        
#if RZOCL_POINTER_ARRAY_AVAILABLE
        self.observerPointerArray = [[NSPointerArray alloc] initWithOptions:(NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality)];
#else
        self.observerAddresses = [NSMutableSet setWithCapacity:10];
#endif
        
    }
    return self;
}

- (void)addObject:(id)observer
{
    if (observer == nil){
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to add nil observer to RZObserverCollection"];
    }
    else{
#if RZOCL_POINTER_ARRAY_AVAILABLE
        [self.observerPointerArray addPointer:(__bridge void *)(observer)];
#else
        NSString *addressString = [NSString stringWithFormat:@"%p", observer];
        if (![self.observerAddresses containsObject:addressString])
        {
            [self.observerAddresses addObject:addressString];
            objc_setAssociatedObject(self, (__bridge const void *)(addressString), observer, OBJC_ASSOCIATION_ASSIGN);
        }
#endif
    }
}

- (void)removeObject:(id)observer
{
    if (observer == nil){
        [NSException raise:NSInternalInconsistencyException format:@"Attempting to remove nil observer from RZObserverCollection"];
    }
    else{
#if RZOCL_POINTER_ARRAY_AVAILABLE
        NSUInteger observerIndex = [self indexOfObserverInPointerArray:observer];
        if (observerIndex != NSNotFound){
            [self.observerPointerArray removePointerAtIndex:observerIndex];
        }
#else
        NSString *addressString = [NSString stringWithFormat:@"%p", observer];
        if ([self.observerAddresses containsObject:addressString])
        {
            [self.observerAddresses removeObject:addressString];
            objc_setAssociatedObject(self, (__bridge const void *)(addressString), nil, OBJC_ASSOCIATION_ASSIGN);
        }
#endif
    }
}

#if RZOCL_POINTER_ARRAY_AVAILABLE

- (NSUInteger)indexOfObserverInPointerArray:(id)observer
{
    __block NSUInteger index = NSNotFound;
    [[self.observerPointerArray allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (obj == observer)
        {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

#endif

#pragma mark - Property Overrides

- (NSArray*)allObjects
{
#if RZOCL_POINTER_ARRAY_AVAILABLE
    return [self.observerPointerArray allObjects];
#else
    NSMutableArray *observers = [NSMutableArray arrayWithCapacity:self.observerAddresses.count];
    for (NSString *obsKey in self.observerAddresses)
    {
        id observer = objc_getAssociatedObject(self, (__bridge const void *)(obsKey));
        if (observer){
            [observers addObject:observer];
        }
    }
    return observers;
#endif
}

@end
