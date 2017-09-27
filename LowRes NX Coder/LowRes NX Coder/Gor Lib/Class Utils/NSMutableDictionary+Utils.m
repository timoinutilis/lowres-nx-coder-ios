//
//  NSMutableDictionary+Utils.m
//  Pixels
//
//  Created by Timo Kloss on 17/8/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "NSMutableDictionary+Utils.h"

@implementation NSMutableDictionary (Utils)

+ (NSMutableDictionary *)dictionaryWithParamsFromURL:(NSURL *)url
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *query = [url query];
    if (query)
    {
        NSArray *components = [query componentsSeparatedByString:@"&"];
        for (NSString *param in components)
        {
            NSArray *elts = [param componentsSeparatedByString:@"="];
            if ([elts count] == 2)
            {
                [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
            }
        }
    }
    return params;
}

@end
