//
//  APIURLCache.m
//  Pixels
//
//  Created by Timo Kloss on 17/12/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "APIURLCache.h"

static NSString *const APIURLCacheExpirationKey = @"APIURLCacheExpiration";
static NSTimeInterval const APIURLCacheExpirationInterval = 600;

@implementation APIURLCache

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    NSCachedURLResponse *cachedResponse = [super cachedResponseForRequest:request];
    
    if (cachedResponse)
    {
        NSDate *cacheDate = cachedResponse.userInfo[APIURLCacheExpirationKey];
        NSDate *cacheExpirationDate = [cacheDate dateByAddingTimeInterval:APIURLCacheExpirationInterval];
        if ([cacheExpirationDate compare:[NSDate date]] == NSOrderedAscending)
        {
            [self removeCachedResponseForRequest:request];
            return nil;
        }
    }
    return cachedResponse;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:cachedResponse.userInfo];
    userInfo[APIURLCacheExpirationKey] = [NSDate date];
    
    NSCachedURLResponse *modifiedCachedResponse = [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:userInfo storagePolicy:cachedResponse.storagePolicy];
    
    [super storeCachedResponse:modifiedCachedResponse forRequest:request];
}

@end
