//
//  NSFetchRequest+RZCreationHelpers.m
//  RZCollectionList-Demo
//
//  Created by Joe Goullaud on 9/13/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import "NSFetchRequest+RZCreationHelpers.h"

@implementation NSFetchRequest (RZCreationHelpers)

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName predicate:(NSPredicate*)predicate
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptors:nil predicate:predicate];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName predicateFormat:(NSString*)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    
    va_end(args);
    
    return request;
}


+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptors:sortDescriptors predicate:nil];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptor:sortDescriptor predicate:nil];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptorKey:key ascending:ascending predicate:nil];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptorKey:key ascending:ascending comparator:comparator predicate:nil];
}


+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors predicate:(NSPredicate*)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    request.sortDescriptors = sortDescriptors;
    request.predicate = predicate;
    
    return request;
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor predicate:(NSPredicate*)predicate
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptors:[NSArray arrayWithObject:sortDescriptor] predicate:predicate];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending predicate:(NSPredicate*)predicate
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending] predicate:predicate];
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator predicate:(NSPredicate*)predicate
{
    return [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending comparator:comparator] predicate:predicate];
}


+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptors:(NSArray*)sortDescriptors predicateFormat:(NSString*)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptors:sortDescriptors predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    
    va_end(args);
    
    return request;
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptor:(NSSortDescriptor*)sortDescriptor predicateFormat:(NSString*)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptor:sortDescriptor predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    
    va_end(args);
    
    return request;
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending predicateFormat:(NSString*)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptorKey:key ascending:ascending predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    
    va_end(args);
    
    return request;
}

+ (NSFetchRequest*)fetchRequestWithEntityName:(NSString*)entityName sortDescriptorKey:(NSString*)key ascending:(BOOL)ascending comparator:(NSComparator)comparator predicateFormat:(NSString*)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName sortDescriptorKey:key ascending:ascending comparator:comparator predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
    
    va_end(args);
    
    return request;
}

@end
