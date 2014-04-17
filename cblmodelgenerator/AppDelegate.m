//
//  AppDelegate.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import "AppDelegate.h"
#import "CBLModelGenerator.h"

@interface AppDelegate ()
@property (strong, nonatomic) CBLModelGenerator* modelGenerator;
@end

@implementation AppDelegate

- (id)initWithModel:(NSString *)modelPath andOutputDirectory:(NSString *)outputPath {
    self = [super init];
    if(self) {
        self.modelGenerator = [[CBLModelGenerator alloc] initWithModel:modelPath andOutputDirectory:outputPath];
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"AppDelegate dealloc");
}

#pragma mark -- NSApplicationDelegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.modelGenerator start];
}

@end
