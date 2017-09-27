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
@property (nonatomic) NSString *sourceCode;
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
    return self.sourceCode != nil;
}

- (BOOL)isShared
{
    return self.sharedPost != nil;
}

- (void)loadSourceCodeWithCompletion:(LCCPostLoadSourceCodeBlock)block
{
    if (self.sourceCode)
    {
        block(self.sourceCode, nil);
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
                    if (response)
                    {
                        self.sourceCode = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    }
                    else
                    {
                        NSLog(@"Error: %@", error.localizedDescription);
                    }
                    for (LCCPostLoadSourceCodeBlock block in self.blocks)
                    {
                        block(self.sourceCode, error);
                    }
                    self.blocks = nil;
                });
                
            }] resume];
        }
    }
}

@end
