//
//  LCCComment.h
//  Pixels
//
//  Created by Timo Kloss on 22/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

@interface LCCComment : APIObject

@property (retain) NSString *user;
@property (retain) NSString *post;
@property (retain) NSString *text;

@end
