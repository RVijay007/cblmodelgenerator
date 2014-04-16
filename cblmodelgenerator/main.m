//
//  main.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBLModelGenerator.h"

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        
        // argc by default is 1 with an argv[0] = to the calling command, './cblmodelgenerator'
        if(argc < 2) {
            printf("Usage: cblmodelgenerator /path/to/xcdatamodeld/ [/path/to/outputdirectory]");
            return 1;
        }
        
        // Append trailing "/" if not present
        NSString* dataModelPath = [NSString stringWithUTF8String:argv[1]];
        if(![dataModelPath hasSuffix:@"/"]) {
            dataModelPath = [@[dataModelPath, @"/"] componentsJoinedByString:@""];
        }
        
        // Make sure this is an xcdatamodeld
        if(![dataModelPath hasSuffix:@".xcdatamodeld/"]) {
            printf("File is not a valid xcdatamodel! Please pass in the xcdatamodeld. Note ending 'd'.\n");
            return 1;
        }
        
        NSString* outputPath = [dataModelPath stringByDeletingLastPathComponent];
        if(argc > 2) {
            outputPath = [NSString stringWithUTF8String:argv[2]];
        }
        
        printf("Reading Core Data model from %s\n\tSaving to %s\n", [dataModelPath UTF8String], [outputPath UTF8String]);
        
        // Initialize and start CBLModelGenerator
        CBLModelGenerator* modelGenerator = [[CBLModelGenerator alloc] initWithModel:dataModelPath andOutputDirectory:outputPath];
         return [modelGenerator start];
    }
    
    return 1;
}

