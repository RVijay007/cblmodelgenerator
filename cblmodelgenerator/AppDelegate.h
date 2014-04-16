//
//  AppDelegate.h
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (id)initWithModel:(NSString*)modelPath andOutputDirectory:(NSString*)outputPath;

@end
