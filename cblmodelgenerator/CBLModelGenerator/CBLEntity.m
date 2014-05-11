//
//  CBLEntity.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import "CBLEntity.h"

@interface CBLEntity ()
@property (strong, nonatomic) NSMutableArray* properties;
@end

@implementation CBLEntity

- (id)init {
    self = [super init];
    if(self) {
        self.className = @"";
        self.parentClassName = @"";
        self.properties = [@[] mutableCopy];
        self.isDynamic = NO;
    }
    
    return self;
}

- (void)addProperty:(id)property {
    if([property isKindOfClass:[CBLEntityAttribute class]] || [property isKindOfClass:[CBLEntityRelationship class]])
        [self.properties addObject:property];
}

- (void)addUserInfoToLastPropertyWithKey:(NSString*)key value:(NSString*)value {
    id lastProperty = [self.properties lastObject];
    NSMutableDictionary* userInfo = [[lastProperty userInfo] mutableCopy];
    userInfo[key] = value;
    [lastProperty setUserInfo:[userInfo copy]];
}

- (void)generateClassesInOutputDirectory:(NSString*)path {
    [self generateHeaderFileInOutputDirectory:path];
    [self generateSourceFileInOutputDirectory:path];
}

#pragma mark - Generate Header File methods

- (void)generateHeaderFileInOutputDirectory:(NSString*)path {
    printf("\tGenerating %s...", [[self.className stringByAppendingPathExtension:@"h"] UTF8String]);
    
    __block NSString* imports = @"//";
    imports = [imports stringByAppendingArray:@[@"//",[self.className stringByAppendingPathExtension:@"h"]] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"cblmodelgenerator"] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"\n"] joinedByString:@"" terminateWith:nil];
    imports = [imports stringByAppendingString:@"\n#import <CouchbaseLite/CouchbaseLite.h>"];
    
    __block NSString* interface = [@[@"@interface", self.className, @":", self.parentClassName] componentsJoinedByString:@" "];
    [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[CBLEntityAttribute class]]) {
            CBLEntityAttribute* attribute = obj;
            interface = [interface stringByAppendingArray:@[[CBLEntity propertyForAttributeType:attribute.type], attribute.name] joinedByString:@" " terminateWith:@";"];
        } else {
            CBLEntityRelationship* relationship = obj;
            interface = [interface stringByAppendingArray:@[@"@property (nonatomic, strong)",[[relationship className] stringByAppendingString:@"*"],relationship.name] joinedByString:@" " terminateWith:@";"];
            NSString* itemClass = relationship.userInfo[@"itemClass"];
            if(itemClass && ![itemClass isEqualToString:@""] && ![itemClass hasPrefix:@"NS"]) {
                // Custom object item class - need to add to imports
                
                // To One relationships with an inverse will cause circular import problems, so we need to forward declare them
                if(!(!relationship.toMany && relationship.hasInverse))
                    imports = [imports stringByAppendingArray:@[@"#import \"",[itemClass stringByAppendingPathExtension:@"h"],@"\""] joinedByString:@"" terminateWith:nil];
                else
                    imports = [imports stringByAppendingArray:@[@"@class ", itemClass] joinedByString:@"" terminateWith:@";"];
            }
        }
    }];
    
    // Combine parts and write to file
    NSString* output = [@[imports, interface, @"@end"] componentsJoinedByString:@"\n\n"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* headerFilePath = [path stringByAppendingPathComponent:[self.className stringByAppendingPathExtension:@"h"]];
    [fileManager removeItemAtPath:headerFilePath error:nil];
    [fileManager createFileAtPath:headerFilePath contents:[output dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    printf("done\n");
}

+ (NSString*)propertyForAttributeType:(NSString*)attributeType {
    NSString* property = @"";
    
    if([attributeType isEqualToString:@"String"]) {
        property = @"strong) NSString*";
    } else if([attributeType isEqualToString:@"Boolean"]) {
        property = @"assign) bool";
    } else if([attributeType isEqualToString:@"Binary"]) {
        property = @"strong) NSData*";
    } else if([attributeType isEqualToString:@"Date"]) {
        property = @"strong) NSDate*";
    } else if([attributeType isEqualToString:@"Decimal"]) {
        property = @"strong) NSDecimalNumber*";
    } else if([attributeType isEqualToString:@"Double"]) {
        property = @"assign) double";
    } else if([attributeType isEqualToString:@"Float"]) {
        property = @"assign) float";
    } else if([attributeType isEqualToString:@"Boolean"]) {
        property = @"assign) bool";
    } else if([attributeType hasPrefix:@"Integer"]) {
        // Map all integer types to Integer
        property = @"assign) int";
    } else {
        printf("\tError - Attribute type %s is undefined. Please change it and run program again!", [attributeType UTF8String]);
        exit(1);
    }
    
    return [@"@property (nonatomic, " stringByAppendingString:property];
}

#pragma mark - Generate Source File methods

- (void)generateSourceFileInOutputDirectory:(NSString*)path {
    printf("\tGenerating %s...", [[self.className stringByAppendingPathExtension:@"m"] UTF8String]);
    
    __block NSString* imports = @"//";
    imports = [imports stringByAppendingArray:@[@"//",[self.className stringByAppendingPathExtension:@"m"]] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"cblmodelgenerator"] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"\n"] joinedByString:@"" terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"#import \"",[self.className stringByAppendingPathExtension:@"h"],@"\""]
                               joinedByString:@"" terminateWith:nil];
    
    __block NSString* implementation = [@[@"@implementation", self.className] componentsJoinedByString:@" "];
    if(self.isDynamic) {
        [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            implementation = [implementation stringByAppendingArray:@[@"@dynamic",[obj name]] joinedByString:@" " terminateWith:@";"];
        }];
        
        implementation = [implementation stringByAppendingString:@"\n\n- (instancetype)initWithNewDocumentInDatabase:(CBLDatabase*)database {\n\tself = [super initWithNewDocumentInDatabase:database];\n\tif(self) {\n\t\tself.type = NSStringFromClass([self class]);\n\t}\n\treturn self;\n}"];
    }
    
    __block NSString* methods = @"";
    [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[CBLEntityRelationship class]]) {
            methods = [methods stringByAppendingString:[CBLEntity itemClassMethodForRelationship:obj]];
            
            // Import header to To One relationships that have an inverse
            CBLEntityRelationship* relationship = obj;
            NSString* itemClass = relationship.userInfo[@"itemClass"];
            if(itemClass && ![itemClass isEqualToString:@""] && ![itemClass hasPrefix:@"NS"]) {
                // Custom object item class - need to add to imports
                
                // To One relationships with an inverse will cause circular import problems, so we need to forward declare them
                if(!relationship.toMany && relationship.hasInverse)
                    imports = [imports stringByAppendingArray:@[@"#import \"",[itemClass stringByAppendingPathExtension:@"h"],@"\""] joinedByString:@"" terminateWith:nil];
            }
        }

        // Only create setters for CBLNestedModels
        if(!self.isDynamic) {
            if([obj isKindOfClass:[CBLEntityRelationship class]]) {
                methods = [methods stringByAppendingString:[CBLEntity setterForEntityRelationship:obj]];
            } else {
                methods = [methods stringByAppendingString:[CBLEntity setterForEntityAttribute:obj]];
            }
        }
    }];
    
    // Combine parts and write to file
    NSString* output = [@[imports, implementation, methods] componentsJoinedByString:@"\n\n"];
    output = [output stringByAppendingString:@"@end"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* sourceFilePath = [path stringByAppendingPathComponent:[self.className stringByAppendingPathExtension:@"m"]];
    [fileManager removeItemAtPath:sourceFilePath error:nil];
    [fileManager createFileAtPath:sourceFilePath contents:[output dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    printf("done\n");
}

+ (NSString*)itemClassMethodForRelationship:(CBLEntityRelationship*)relationship {
    if(relationship.toMany == YES && relationship.userInfo[@"itemClass"]) {
        return [NSString stringWithFormat:@"+ (Class)%@ItemClass {\n\treturn [%@ class];\n}\n\n", relationship.name, relationship.userInfo[@"itemClass"]];
    } else
        return @"";
}

+ (NSString*)setterForEntityAttribute:(CBLEntityAttribute*)attribute {
    NSString* attributeType = attribute.type;
    NSString* type = @"";
    
    if([attributeType isEqualToString:@"String"]) {
        type = @"NSString*";
    } else if([attributeType isEqualToString:@"Boolean"]) {
        type = @"bool";
    } else if([attributeType isEqualToString:@"Binary"]) {
        type = @"NSData*";
    } else if([attributeType isEqualToString:@"Date"]) {
        type = @"NSDate*";
    } else if([attributeType isEqualToString:@"Decimal"]) {
        type = @"NSDecimalNumber*";
    } else if([attributeType isEqualToString:@"Double"]) {
        type = @"double";
    } else if([attributeType isEqualToString:@"Float"]) {
        type = @"float";
    } else if([attributeType isEqualToString:@"Boolean"]) {
        type = @"bool";
    } else if([attributeType hasPrefix:@"Integer"]) {
        // Map all integer types to Integer
        type = @"int";
    } else {
        printf("\tError - Setter attribute type %s is undefined. Please change it and run program again!", [attributeType UTF8String]);
        exit(1);
    }
    
    NSString* setter = [NSString stringWithFormat:@"- (void)set%@:(%@)%@ {\n\t_%@ = %@;\n\t[self modified];\n}\n\n",
                        [attribute.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[attribute.name substringToIndex:1] capitalizedString]],
                        type, attribute.name, attribute.name, attribute.name];
    
    return setter;
}

+ (NSString*)setterForEntityRelationship:(CBLEntityRelationship*)relationship {
    NSString* setter = [NSString stringWithFormat:@"- (void)set%@:(%@*)%@ {\n\t_%@ = %@;\n\t[self modified];\n\t[self propagateParentTo:%@];\n}\n\n",
                        [relationship.name stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[relationship.name substringToIndex:1] capitalizedString]],
                        relationship.className, relationship.name, relationship.name, relationship.name, relationship.name];
    return setter;
}

#pragma mark - NSObject overloaded methods

- (NSString*)description {
    return [@{@"name" : self.className,
              @"parent" : self.parentClassName,
              @"isDynamic" : @(self.isDynamic),
              @"properties" : self.properties} description];
}

@end

//////////////////////////////////////////////////////////////////////////////////////

@implementation CBLEntityAttribute

- (id)init {
    self = [super init];
    if(self) {
        self.name = @"";
        self.type = @"";
        self.userInfo = [@{} mutableCopy];
    }
    
    return self;
}

- (NSString*)description {
    return [@{@"name" : self.name,
              @"type" : self.type} description];
}

@end

//////////////////////////////////////////////////////////////////////////////////////

@implementation CBLEntityRelationship

- (id)init {
    self = [super init];
    if(self) {
        self.name = @"";
        self.userInfo = [@{} mutableCopy];
        self.toMany = NO;
        self.isOrdered = NO;
        self.hasInverse = NO;
    }
    
    return self;
}

- (NSString*)className {
    if(self.isOrdered)
        return @"NSArray";
    else if(self.toMany)
        return @"NSDictionary";
    else
        return self.userInfo[@"itemClass"];
}

- (NSString*)description {
    return [@{@"name" : self.name,
              @"toMany" : @(self.toMany),
              @"isOrdered" : @(self.isOrdered),
              @"userInfo" : self.userInfo} description];
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@implementation NSString (LineAddition)

- (NSString*)stringByAppendingArray:(NSArray*)stringArray joinedByString:(NSString*)separator terminateWith:(NSString*)terminationString {
    NSString* arrayString = [stringArray componentsJoinedByString:separator];
    if(terminationString)
        arrayString = [arrayString stringByAppendingString:terminationString];
    return [@[self, arrayString] componentsJoinedByString:@"\n"];
}

@end
