//
//  CBLModelGenerator.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import "CBLModelGenerator.h"

@implementation CBLModelGenerator

- (id)initWithModel:(NSString*)modelPath andOutputDirectory:(NSString*)outputPath {
    self = [super init];
    if(self) {
        self.modelPath = modelPath;
        self.outputPath = outputPath;
    }
    
    return self;
}

- (int)start {
    int code = 0;
    
    
    return code;
}

@end
