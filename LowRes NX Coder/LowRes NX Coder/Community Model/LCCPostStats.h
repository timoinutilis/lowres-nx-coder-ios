//
//  LCCPostStats.h
//  Pixels
//
//  Created by Timo Kloss on 24/7/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "APIObject.h"

@interface LCCPostStats : APIObject

@property (retain) NSString *post;
@property int numLikes;
@property int numDownloads;
@property int numComments;
@property BOOL featured;
@property BOOL highlighted;

@end
