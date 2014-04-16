//
//  CBLModelGenerator.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import "CBLModelGenerator.h"
#import <AppKit/AppKit.h>

@interface CBLModelGenerator ()
@property (copy, nonatomic) NSString* modelPath;
@property (copy, nonatomic) NSString* outputPath;
@property (assign, nonatomic) BOOL errorParsing;
@end

@implementation CBLModelGenerator

- (id)initWithModel:(NSString*)modelPath andOutputDirectory:(NSString*)outputPath {
    self = [super init];
    if(self) {
        self.modelPath = modelPath;
        self.outputPath = outputPath;
        self.errorParsing = NO;
    }
    
    return self;
}

- (int)start {
    int code = 0;
    
    printf("Reading Core Data model from %s\n", [self.modelPath UTF8String]);
    [self currentVersionModelFilePath];
    printf("\tLoading current version of model: %s\n", [[self.modelPath lastPathComponent] UTF8String]);
    [self parseCoreDataModel];
    
    return code;
}

// Returns path to contents file for the current version model
- (void)currentVersionModelFilePath {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* xccurrentversionPath = [self.modelPath stringByAppendingPathComponent:@".xccurrentversion"];
    
    if([fileManager fileExistsAtPath:xccurrentversionPath]) {
        NSDictionary* xccurrentversionPlist = [NSDictionary dictionaryWithContentsOfFile:xccurrentversionPath];
        NSString* currentModelName = xccurrentversionPlist[@"_XCCurrentVersionName"];
        self.modelPath = [self.modelPath stringByAppendingPathComponent:currentModelName];
    } else {
        // New models do not have the xccurrentversion file and only one model
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self endswith %@", @".xcdatamodel"];
        NSArray* contents = [[fileManager contentsOfDirectoryAtPath:self.modelPath error:nil] filteredArrayUsingPredicate:predicate];
        if(contents.count == 1){
            self.modelPath = [self.modelPath stringByAppendingPathComponent:[contents lastObject]];
        }
    }
}

- (void)parseCoreDataModel {
    NSString* contentFilePath = [self.modelPath stringByAppendingPathComponent:@"contents"];
    NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:contentFilePath]];
    [parser setDelegate:self];
    if(!parser)
        printf("\tCould not load xml parser\n");
    else
        [parser parse];
}

#pragma mark -- NSXMLParser Delegate Methods

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSString* errorString = [NSString stringWithFormat:@"Error code %ld", [parseError code]];
    printf("\tError parsing XML: %s\n", [errorString UTF8String]);
    self.errorParsing = YES;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{

    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.errorParsing == NO) {
        printf("\tXML parsing done!\n");
    } else {
        printf("\tError parsing XML!\n");
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

@end
