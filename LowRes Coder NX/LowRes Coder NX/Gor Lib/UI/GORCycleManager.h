//
//  GORNextFieldManager.h
//  Pixels
//
//  Created by Timo Kloss on 27/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GORCycleManager : NSObject

@property (nonatomic) NSArray *fields;
@property (strong) void (^endBlock)(void);

- (instancetype)initWithFields:(NSArray *)fields;
- (instancetype)initWithFields:(NSArray *)fields endBlock:(void (^)(void))block;

@end
