//
//  LCCPost.m
//  Pixels
//
//  Created by Timo Kloss on 21/5/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "LCCPost.h"
#import "CommunityModel.h"

@interface LCCPost()
@property (nonatomic) NSData *programData;
@property (nonatomic) BOOL isLoadingSourceCode;
@property (nonatomic) NSMutableArray<LCCPostLoadSourceCodeBlock> *blocks;
@end

@implementation LCCPost

@dynamic user;
@dynamic type;
@dynamic category;
@dynamic image;
@dynamic title;
@dynamic detail;
@dynamic program;
@dynamic sharedPost;
@dynamic stats;

- (NSString *)categoryString
{
    switch (self.category)
    {
        case LCCPostCategoryGame:
            return @"Game";
        case LCCPostCategoryTool:
            return @"Tool";
        case LCCPostCategoryDemo:
            return @"Demo";
        case LCCPostCategoryStatus:
            return @"Status Update";
        case LCCPostCategoryForumHowTo:
            return @"How To";
        case LCCPostCategoryForumCollaboration:
            return @"Collaboration";
        case LCCPostCategoryForumDiscussion:
            return @"Discussion";
        default:
            return @"Unknown";
    }
}

- (BOOL)isSourceCodeLoaded
{
    return self.programData != nil;
}

- (BOOL)isShared
{
    return self.sharedPost != nil;
}

- (void)loadSourceCodeWithCompletion:(LCCPostLoadSourceCodeBlock)block
{
    if (self.programData)
    {
        block(self.programData, nil);
    }
    else
    {
        if (self.blocks == nil)
        {
            self.blocks = [NSMutableArray array];
        }
        [self.blocks addObject:block];
        
        if (!self.isLoadingSourceCode)
        {
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            
            [[session dataTaskWithURL:self.program completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse && httpResponse.statusCode == 200)
                    {
                        self.programData = data;
                    }
                    else
                    {
                        NSLog(@"Error: %@", error.localizedDescription);
                    }
                    for (LCCPostLoadSourceCodeBlock block in self.blocks)
                    {
                        block(self.programData, error);
                    }
                    self.blocks = nil;
                });
                
            }] resume];
        }
    }
}

- (void)loadImageWithCompletion:(LCCPostLoadImageBlock)block
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[session dataTaskWithURL:self.image completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse && httpResponse.statusCode == 200)
            {
                block(data, nil);
            }
            else
            {
                block(nil, error);
                NSLog(@"Error: %@", error.localizedDescription);
            }
        });
        
    }] resume];
}

@end
