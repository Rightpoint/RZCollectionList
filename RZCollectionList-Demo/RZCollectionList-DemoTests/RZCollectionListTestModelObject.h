//
//  RZCollectionListTestModelObject.h
//  RZCollectionList-Demo
//
//  Created by Nick Donaldson on 6/19/13.
//  Copyright (c) 2013 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RZCollectionListTestModelObject : NSObject

+ (RZCollectionListTestModelObject*)objectWithName:(NSString*)name number:(NSNumber*)number;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *number;

@end
