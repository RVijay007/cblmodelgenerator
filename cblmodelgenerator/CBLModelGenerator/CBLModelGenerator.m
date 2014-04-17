//
//  CBLModelGenerator.m
//  cblmodelgenerator
//
//  Created by Ragu Vijaykumar on 4/16/14.
//  Copyright (c) 2014 RVijay007. All rights reserved.
//

#import "CBLModelGenerator.h"
#import <AppKit/AppKit.h>
#import "CBLEntity.h"

@interface CBLModelGenerator ()
@property (copy, nonatomic) NSString* modelPath;
@property (copy, nonatomic) NSString* outputPath;
@property (strong, nonatomic) NSMutableArray* entities;
@property (strong, nonatomic) NSMutableSet* dynamicEntities;

@property (assign, nonatomic) BOOL errorParsing;
@end

@implementation CBLModelGenerator

- (id)initWithModel:(NSString*)modelPath andOutputDirectory:(NSString*)outputPath {
    self = [super init];
    if(self) {
        self.modelPath = modelPath;
        self.outputPath = outputPath;
        self.entities = [@[] mutableCopy];
        self.dynamicEntities = [NSMutableSet set];
        [self.dynamicEntities addObject:@"CBLModel"];
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
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[NSData dataWithContentsOfFile:contentFilePath]];
    
    if(!parser)
        printf("\tCould not load XML parser\n");
    else {
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldResolveExternalEntities:NO];
        [parser setDelegate:self];
        
        [parser parse];
    }
}

#pragma mark - NSXMLParser Delegate Methods

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
    
    if([elementName isEqualToString:@"model"]) {
        return;
    } else if([elementName isEqualToString:@"entity"]) {
        NSString* className = attributeDict[@"representedClassName"];
        if(!([className isEqualToString:@"CBLModel"] || [className isEqualToString:@"CBLNestedModel"])) {
            // Only process entities not part of CBL
            printf("\tParsing %s...\n", [className UTF8String]);
            
            CBLEntity* entity = [[CBLEntity alloc] init];
            entity.className = className;
            entity.parentClassName = attributeDict[@"parentEntity"];
            
            // CBLModels generate dynamic properties, CBLNestedModels do not
            if([self.dynamicEntities containsObject:entity.parentClassName]) {
                entity.isDynamic = YES;
                [self.dynamicEntities addObject:entity.className];
            }
            
            [self.entities addObject:entity];
        }
    } else if([elementName isEqualToString:@"attribute"]) {
        CBLEntity* entity = [self.entities lastObject];
        CBLEntityAttribute* attribute = [[CBLEntityAttribute alloc] init];
        [entity addProperty:attribute];
        
        attribute.name = attributeDict[@"name"];
        attribute.type = attributeDict[@"attributeType"];
        
    } else if([elementName isEqualToString:@"relationship"]) {
        CBLEntity* entity = [self.entities lastObject];
        CBLEntityRelationship* relationship = [[CBLEntityRelationship alloc] init];
        [entity addProperty:relationship];
        
        relationship.name = attributeDict[@"name"];
        if([attributeDict[@"toMany"] isEqualToString:@"YES"]) {
            relationship.toMany = YES;
        }
        
        if([attributeDict[@"ordered"] isEqualToString:@"YES"]) {
            relationship.isOrdered = YES;
        }
        
        if(attributeDict[@"destinationEntity"]) {
            [entity addUserInfoToLastPropertyWithKey:@"itemClass" value:attributeDict[@"destinationEntity"]];
        }

    } else if([elementName isEqualToString:@"entry"]) {
        CBLEntity* entity = [self.entities lastObject];
        [entity addUserInfoToLastPropertyWithKey:attributeDict[@"key"] value:attributeDict[@"value"]];
    }
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    // Does Nothing
}


- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (self.errorParsing == NO) {
        printf("Finished parsing model classes! Writing class files to %s.\n", [self.outputPath UTF8String]);
        [self.entities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj generateClassesInOutputDirectory:self.outputPath];
        }];
    } else {
        printf("\tError parsing core data file!\n");
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

@end
