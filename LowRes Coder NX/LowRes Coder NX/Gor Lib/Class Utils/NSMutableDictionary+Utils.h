//
//  NSMutableDictionary+Utils.h
//  Pixels
//
//  Created by Timo Kloss on 17/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Utils)

+ (NSMutableDictionary *)dictionaryWithParamsFromURL:(NSURL *)url;

@end
