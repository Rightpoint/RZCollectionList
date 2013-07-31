//
//  NSFetchRequest+RZCreationHelpers.h
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSFetchRequest (RZCreationHelpers)

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName predicateFormat:(NSString*)predicateFormat, ...;

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator;

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors predicate:(NSPredicate*)predicate;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor predicate:(NSPredicate*)predicate;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending predicate:(NSPredicate*)predicate;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator predicate:(NSPredicate*)predicate;

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors predicateFormat:(NSString*)predicateFormat, ...;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor predicateFormat:(NSString*)predicateFormat, ...;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending predicateFormat:(NSString*)predicateFormat, ...;
+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator predicateFormat:(NSString*)predicateFormat, ...;

@end
