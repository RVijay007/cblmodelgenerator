//
//  CBLEntity.h
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBLEntityAttribute, CBLEntityRelationship;

@interface CBLEntity : NSObject

@property (copy, nonatomic) NSString* className;
@property (copy, nonatomic) NSString* parentClassName;
@property (assign, nonatomic) BOOL isDynamic;

- (void)addProperty:(id)property;
- (void)addUserInfoToLastPropertyWithKey:(NSString*)key value:(NSString*)value;

- (void)generateClassesInOutputDirectory:(NSString*)path;

@end

//////////////////////////////////////////////////////////////////////////////////////

@interface CBLEntityAttribute : NSObject
@property (copy, nonatomic) NSString* name;
@property (copy, nonatomic) NSString* type;
@property (strong, nonatomic) NSDictionary* userInfo;

@end

///////////////////////////////////////////////////////////////////////////////////////

@interface CBLEntityRelationship : NSObject
@property (copy, nonatomic) NSString* name;
@property (assign, nonatomic) BOOL toMany;                  // Represents an NSDictionary or NSArray
@property (assign, nonatomic) BOOL isOrdered;               // Represents an NSArray if YES, NSDictionary if NO
@property (assign, nonatomic) BOOL hasInverse;              // If the relationship contains an inverse, default is NO
@property (strong, nonatomic) NSDictionary* userInfo;

- (NSString*)className;

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface NSString (LineAddition)

- (NSString*)stringByAppendingArray:(NSArray*)stringArray joinedByString:(NSString*)separator terminateWith:(NSString*)terminationString;

@end