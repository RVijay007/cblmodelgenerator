//
//  main.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        
        // argc by default is 1 with an argv[0] = to the calling command, './cblmodelgenerator'
        if(argc < 2) {
            printf("Usage: cblmodelgenerator /path/to/xcdatamodeld/ [/path/to/outputdirectory]\n");
            return 1;
        }

        // Make sure this is an xcdatamodeld file path
        NSString* dataModelPath = [NSString stringWithUTF8String:argv[1]];
        if(![[dataModelPath pathExtension] isEqualToString:@"xcdatamodeld"]) {
            printf("File is not a valid xcdatamodel! Please pass in the xcdatamodeld. Note ending 'd'.\n");
            return 1;
        }
        
        // Detemine what the output directory is going to be
        NSString* outputPath = [dataModelPath stringByDeletingLastPathComponent];
        if(argc > 2) {
            outputPath = [NSString stringWithUTF8String:argv[2]];
        }
        
        // Initialize and start CBLModelGenerator
        AppDelegate* delegate = [[AppDelegate alloc] initWithModel:dataModelPath andOutputDirectory:outputPath];
        [[NSApplication sharedApplication] setDelegate:delegate];
        [[NSApplication sharedApplication] run];
    }
    
    return 0;
}

