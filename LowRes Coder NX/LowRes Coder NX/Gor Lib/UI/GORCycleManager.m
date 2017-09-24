//
//  GORNextFieldManager.m
//  Pixels
//
//  Created by Timo Kloss on 27/6/15.
//  Copyright (c) 2015 Inutilis Software. All rights reserved.
//

#import "GORCycleManager.h"

@implementation GORCycleManager

- (instancetype)initWithFields:(NSArray *)fields
{
    return [self initWithFields:fields endBlock:nil];
}

- (instancetype)initWithFields:(NSArray *)fields endBlock:(void (^)(void))block
{
    if (self = [super init])
    {
        self.fields = fields;
        self.endBlock = block;
    }
    return self;
}

- (void)setFields:(NSArray *)fields
{
    _fields = fields;
    for (id field in fields)
    {
        if ([field isKindOfClass:[UITextField class]])
        {
            UITextField *textField = field;
            [textField addTarget:self action:@selector(onTextFieldReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];
        }
        else if ([field isKindOfClass:[UITextView class]])
        {
//            UITextView *textView = field;
        }
        else
        {
            [NSException raise:@"UnsupportedClass" format:@"Unsupported class"];
        }
    }
}

- (void)onTextFieldReturn:(UITextField *)textField
{
    NSUInteger index = [self.fields indexOfObject:textField];
    if (index != NSNotFound)
    {
        if (index < self.fields.count - 1)
        {
            UIResponder *nextField = self.fields[index + 1];
            [nextField becomeFirstResponder];
        }
        else
        {
            [textField resignFirstResponder];
            if (self.endBlock)
            {
                self.endBlock();
            }
        }
    }
}

@end
