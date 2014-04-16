//
//  main.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        
        // argc by default is 1 with an argv[0] = to the calling command, './cblmodelgenerator'
        if(argc != 2) {
            printf("Please pass in the path to your xcdatamodeld file as the only argument\n");
            return 1;
        } else {
            printf("Reading Core Data model from %s\n", argv[1]);
        }
        
        // Append trailing "/" if not present
        NSString* path = [NSString stringWithUTF8String:argv[1]];
        if(![path hasSuffix:@"/"]) {
            path = [@[path, @"/"] componentsJoinedByString:@""];
        }
        
        // Make sure this is an xcdatamodeld
        if(![path hasSuffix:@".xcdatamodeld/"]) {
            printf("File is not a valid xcdatamodel! Please pass in the xcdatamodeld. Note ending 'd'.\n");
            return 1;
        }
        
        
        
    }
    return 0;
}

