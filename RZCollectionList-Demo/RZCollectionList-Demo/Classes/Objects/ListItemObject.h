//
//  ListItemObject.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ListItemObject : NSObject

@property (nonatomic, strong) NSString * itemName;
@property (nonatomic, strong) NSString * subtitle;

+ (id)listItemObjectWithName:(NSString*)itemName subtitle:(NSString*)subtitle;

- (id)initWithItemName:(NSString*)itemName subtitle:(NSString*)subtitle;

@end
