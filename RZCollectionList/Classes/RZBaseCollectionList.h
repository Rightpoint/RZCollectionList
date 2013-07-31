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
 *  Base class for providing common variables and
 *  utils for classes implementing the RZCollectionList protocol.
 *
 *  Classes implementing the protocol are not required to use this
 *  as a base class.
 *
 *  This class implements the protocol itself, but requires 
 *  subclasses to override the protocol methods, or a runtime
 *  exception will be thrown when an unimplemented method is
 *  called.
 *
 ****************************************************************/

@interface RZBaseCollectionList : NSObject <RZCollectionList>

@end