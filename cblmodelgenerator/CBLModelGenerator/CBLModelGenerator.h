//
//  CBLModelGenerator.h
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CBLModelGenerator : NSObject

@property (copy, nonatomic) NSString* modelPath;
@property (copy, nonatomic) NSString* outputPath;

- (id)initWithModel:(NSString*)modelPath andOutputDirectory:(NSString*)outputPath;

- (int)start;

@end
