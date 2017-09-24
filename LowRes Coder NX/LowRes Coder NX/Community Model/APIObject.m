//
//  APIObject.m
//  Pixels
//
//  Created by Timo Kloss on 12/11/16.
//  Copyright © 2016 Inutilis Software. All rights reserved.
//

#import "APIObject.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, APIObjectPropertyType) {
    APIObjectPropertyTypeString,
    APIObjectPropertyTypeDate,
    APIObjectPropertyTypeURL,
    APIObjectPropertyTypeInteger,
    APIObjectPropertyTypeBool
};

static NSMutableDictionary *_dynamicProperties;


@interface APIObject()

@property (nonatomic) NSMutableDictionary *values;
@property (nonatomic) NSMutableSet *dirty;

@end


@interface APIObjectProperty : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) BOOL isSetter;
@property (nonatomic) APIObjectPropertyType type;

- (instancetype)initWithName:(NSString *)name type:(APIObjectPropertyType)type isSetter:(BOOL)isSetter;

@end


id objectGetterMethodIMP(APIObject *self, SEL _cmd)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    id value = self.values[property.name];
    if (value) // && value != [NSNull null])
    {
        return value;
    }
    return nil;
}

void objectSetterMethodIMP(APIObject *self, SEL _cmd, id value)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    if (value)
    {
        self.values[property.name] = value;
    }
    else
    {
        [self.values removeObjectForKey:property.name];
    }
    [self.dirty addObject:property.name];
}

int integerGetterMethodIMP(APIObject *self, SEL _cmd)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    id value = self.values[property.name];
    return [value intValue];
}

void integerSetterMethodIMP(APIObject *self, SEL _cmd, int value)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    self.values[property.name] = @(value);
    [self.dirty addObject:property.name];
}

BOOL boolGetterMethodIMP(APIObject *self, SEL _cmd)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    id value = self.values[property.name];
    return [value boolValue];
}

void boolSetterMethodIMP(APIObject *self, SEL _cmd, BOOL value)
{
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass([self class])][NSStringFromSelector(_cmd)];
    self.values[property.name] = @(value);
    [self.dirty addObject:property.name];
}


@implementation APIObject

+ (void)registerAPIClass
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dynamicProperties = [NSMutableDictionary dictionary];
    });
    
    NSMutableDictionary *classProperties = [NSMutableDictionary dictionary];
    _dynamicProperties[NSStringFromClass(self)] = classProperties;
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    
    for (unsigned int i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        
        NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
        BOOL isDynamic = [attributes rangeOfString:@",D"].location != NSNotFound;
        
        if (isDynamic)
        {
            NSString *name = [NSString stringWithUTF8String:property_getName(property)];
            NSString *getterName = name;
            NSString *setterName = [NSString stringWithFormat:@"set%@%@:", [[name substringToIndex:1] capitalizedString], [name substringFromIndex:1]];
            APIObjectPropertyType type;
            unichar typeChar = [attributes characterAtIndex:1];
            switch (typeChar)
            {
                case '@': {
                    NSUInteger start = [attributes rangeOfString:@"\""].location + 1;
                    NSUInteger end = [attributes rangeOfString:@"\"" options:0 range:NSMakeRange(start, attributes.length - start)].location - 1;
                    NSString *className = [attributes substringWithRange:NSMakeRange(start, end - start + 1)];
                    
                    if ([className isEqualToString:@"NSString"])
                    {
                        type = APIObjectPropertyTypeString;
                    }
                    else if ([className isEqualToString:@"NSDate"])
                    {
                        type = APIObjectPropertyTypeDate;
                    }
                    else if ([className isEqualToString:@"NSURL"])
                    {
                        type = APIObjectPropertyTypeURL;
                    }
                    else
                    {
                        type = APIObjectPropertyTypeString;
                        NSAssert(NO, @"Class type not implemented: %@", className);
                    }
                    break;
                }
                    
                case 'i':
                case 'l':
                case 's':
                    type = APIObjectPropertyTypeInteger;
                    break;

                case 'B':
                case 'c':
                    type = APIObjectPropertyTypeBool;
                    break;

                default:
                    type = APIObjectPropertyTypeString;
                    NSAssert(NO, @"Data type not implemented: %c", typeChar);
            }
            
            classProperties[getterName] = [[APIObjectProperty alloc] initWithName:name type:type isSetter:NO];
            classProperties[setterName] = [[APIObjectProperty alloc] initWithName:name type:type isSetter:YES];
        }
    }
    
    if (properties)
    {
        free(properties);
    }
}

+ (NSArray *)objectsFromArray:(NSArray<NSDictionary *> *)array
{
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:array.count];
    
    for (NSDictionary *dictionary in array)
    {
        APIObject *object = [[self alloc] initWithDictionary:dictionary];
        [objects addObject:object];
    }
    
    return objects;
}

+ (NSDictionary *)objectsByIdFromArray:(NSArray<NSDictionary *> *)array
{
    NSMutableDictionary *objects = [NSMutableDictionary dictionaryWithCapacity:array.count];
    
    for (NSDictionary *dictionary in array)
    {
        APIObject *object = [[self alloc] initWithDictionary:dictionary];
        objects[object.objectId] = object;
    }
    
    return objects;
}

- (instancetype)init
{
    if (self = [super init])
    {
        NSAssert(_dynamicProperties[NSStringFromClass(self.class)], @"registerAPIClass not called for %@", NSStringFromClass(self.class));
        _values = [NSMutableDictionary dictionary];
        _dirty = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithObjectId:(NSString *)objectId
{
    if (self = [self init])
    {
        _objectId = objectId;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init])
    {
        [self updateWithDictionary:dictionary];
    }
    return self;
}

- (instancetype)initWithNativeDictionary:(NSDictionary *)dictionary
{
    if (self = [self init])
    {
        _objectId = dictionary[@"objectId"];
        _createdAt = dictionary[@"createdAt"];
        _updatedAt = dictionary[@"updatedAt"];
        
        _values = dictionary.mutableCopy;
        [_values removeObjectForKey:@"objectId"];
        [_values removeObjectForKey:@"createdAt"];
        [_values removeObjectForKey:@"updatedAt"];
    }
    return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *classProperties = _dynamicProperties[NSStringFromClass([self class])];
    for (NSString *key in dictionary)
    {
        id value = dictionary[key];
        if (value && value != [NSNull null] && ![value isKindOfClass:[NSDictionary class]])
        {
            if ([key isEqualToString:@"objectId"])
            {
                _objectId = value;
            }
            else if ([key isEqualToString:@"createdAt"])
            {
                _createdAt = [[NSDateFormatter sharedAPIDateFormatter] dateFromString:value];
            }
            else if ([key isEqualToString:@"updatedAt"])
            {
                _updatedAt = [[NSDateFormatter sharedAPIDateFormatter] dateFromString:value];
            }
            else
            {
                APIObjectProperty *property = classProperties[key];
                if (!property)
                {
                    NSLog(@"Warning: Key not defined as property: %@", key);
                }
                else
                {
                    switch (property.type)
                    {
                        case APIObjectPropertyTypeString:
                            self.values[property.name] = value;
                            break;

                        case APIObjectPropertyTypeDate:
                            self.values[property.name] = [[NSDateFormatter sharedAPIDateFormatter] dateFromString:value];
                            break;
                            
                        case APIObjectPropertyTypeURL:
                            self.values[property.name] = [NSURL URLWithString:value];
                            break;
                            
                        case APIObjectPropertyTypeInteger:
                            self.values[property.name] = @([value intValue]);
                            break;
                            
                        case APIObjectPropertyTypeBool:
                            self.values[property.name] = @([value boolValue]);
                            break;
                    }
                    [self.dirty removeObject:property.name];
                }
            }
        }
    }
}

- (NSDictionary *)dirtyDictionary
{
    NSDictionary *classProperties = _dynamicProperties[NSStringFromClass([self class])];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    for (NSString *key in self.dirty)
    {
        id value = self.values[key];
        APIObjectProperty *property = classProperties[key];
        switch (property.type)
        {
            case APIObjectPropertyTypeString:
            case APIObjectPropertyTypeInteger:
            case APIObjectPropertyTypeBool:
                dictionary[key] = value;
                break;
                
            case APIObjectPropertyTypeDate:
                dictionary[key] = [[NSDateFormatter sharedAPIDateFormatter] stringFromDate:value];
                break;
                
            case APIObjectPropertyTypeURL:
                dictionary[key] = ((NSURL *)value).absoluteString;
                break;
        }
    }
    
    return dictionary;
}

- (void)resetDirty
{
    [self.dirty removeAllObjects];
}

- (NSDictionary *)nativeDictionary
{
    NSMutableDictionary *dict = self.values.mutableCopy;
    if (self.objectId)
    {
        dict[@"objectId"] = self.objectId;
    }
    if (self.createdAt)
    {
        dict[@"createdAt"] = self.createdAt;
    }
    if (self.updatedAt)
    {
        dict[@"updatedAt"] = self.updatedAt;
    }
    return dict;
}

+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    NSString *selectorString = NSStringFromSelector(aSEL);
    APIObjectProperty *property = _dynamicProperties[NSStringFromClass(self)][selectorString];
    if (property)
    {
        if (property.isSetter)
        {
            switch (property.type)
            {
                case APIObjectPropertyTypeString:
                case APIObjectPropertyTypeDate:
                case APIObjectPropertyTypeURL:
                    class_addMethod([self class], aSEL, (IMP)objectSetterMethodIMP, "v@:@");
                    break;
                    
                case APIObjectPropertyTypeInteger:
                    class_addMethod([self class], aSEL, (IMP)integerSetterMethodIMP, "v@:i");
                    break;
                    
                case APIObjectPropertyTypeBool:
                    class_addMethod([self class], aSEL, (IMP)boolSetterMethodIMP, "v@:B");
                    break;
            }
        }
        else
        {
            switch (property.type)
            {
                case APIObjectPropertyTypeString:
                case APIObjectPropertyTypeDate:
                case APIObjectPropertyTypeURL:
                    class_addMethod([self class], aSEL, (IMP)objectGetterMethodIMP, "@@:");
                    break;
                    
                case APIObjectPropertyTypeInteger:
                    class_addMethod([self class], aSEL, (IMP)integerGetterMethodIMP, "i@:");
                    break;
                    
                case APIObjectPropertyTypeBool:
                    class_addMethod([self class], aSEL, (IMP)boolGetterMethodIMP, "B@:");
                    break;
            }
        }
        return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}

@end


@implementation APIObjectProperty

- (instancetype)initWithName:(NSString *)name type:(APIObjectPropertyType)type isSetter:(BOOL)isSetter
{
    if (self = [self init])
    {
        _name = name;
        _type = type;
        _isSetter = isSetter;
    }
    return self;
}

@end


@implementation NSDateFormatter (APIObject)

+ (NSDateFormatter *)APIDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return dateFormatter;
}

+ (NSDateFormatter *)sharedAPIDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [NSDateFormatter APIDateFormatter];
    });
    return dateFormatter;
}

@end
