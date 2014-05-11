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
        self.outputPath = [outputPath stringByAppendingPathComponent:@"generated"];
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
        
        // Sometimes, user forgets to set class name as the same name as the name
        if(!className || [className isEqualToString:@""])
            className = attributeDict[@"name"];
        
        if(!([className isEqualToString:@"CBLModel"] || [className isEqualToString:@"CBLNestedModel"])) {
            // Only process entities not part of CBL
            printf("\tParsing %s...\n", [className UTF8String]);
            
            CBLEntity* entity = [[CBLEntity alloc] init];
            entity.className = className;
            entity.parentClassName = attributeDict[@"parentEntity"];
            
            if(!entity.parentClassName) {
                // Alternate way of making CBLModels is to define the class as abstract, CBLNestedModel if not
                if([attributeDict[@"isAbstract"] isEqualToString:@"YES"])
                    entity.parentClassName = @"CBLModel";
                else
                    entity.parentClassName = @"CBLNestedModel";
            }
            
            // CBLModels generate dynamic properties, CBLNestedModels do not
            if([self.dynamicEntities containsObject:entity.parentClassName]) {
                entity.isDynamic = YES;
                [self.dynamicEntities addObject:entity.className];
            }
            
            [self.entities addObject:entity];
        }
    } else if([elementName isEqualToString:@"attribute"]) {
        CBLEntity* entity = [self.entities lastObject];
        if([attributeDict[@"attributeType"] isEqualToString:@"Transformable"]) {
            // Transformable is used for properties that have non-JSON objects or collections to such
            // These are very similar to relationships; in fact, you can think of them as
            // "relationships" to objects not displayed your model file (*.xcdatamodel)
            
            CBLEntityRelationship* relationship = [[CBLEntityRelationship alloc] init];
            [entity addProperty:relationship];
            
            NSString* valueTransformerName = attributeDict[@"valueTransformerName"];
            relationship.name = attributeDict[@"name"];
            if([valueTransformerName isEqualToString:@"NSArray"]) {
                // An NSArray of objects, defined by itemClass key in userInfo if non-JSON compatible
                relationship.toMany = YES;
                relationship.isOrdered = YES;
            } else if ([valueTransformerName isEqualToString:@"NSDictionary"]) {
                // An NSDictionary of objects, defined by itemClass key in userInfo if non-JSON compatible
                relationship.toMany = YES;
                relationship.isOrdered = NO;
            } else {
                // Mon-JSON style object
                relationship.toMany = NO;
                relationship.isOrdered = NO;
                [entity addUserInfoToLastPropertyWithKey:@"itemClass" value:valueTransformerName];
            }
            
        } else {
            CBLEntityAttribute* attribute = [[CBLEntityAttribute alloc] init];
            [entity addProperty:attribute];
            
            attribute.name = attributeDict[@"name"];
            attribute.type = attributeDict[@"attributeType"];
        }
        
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
        
        if(attributeDict[@"inverseName"]) {
            relationship.hasInverse = YES;
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
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:self.outputPath isDirectory:nil])
            [[NSFileManager defaultManager] createDirectoryAtPath:self.outputPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [self.entities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj generateClassesInOutputDirectory:self.outputPath];
        }];
        
        [self createModelFactoryRegistery];
    } else {
        printf("\tError parsing core data file!\n");
    }
    
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - Model Factory class

- (void)createModelFactoryRegistery {
    NSString* factoryClassName = [[self.modelPath lastPathComponent] stringByDeletingPathExtension];
    factoryClassName = [factoryClassName stringByAppendingString:@"ModelFactory"];
    
    // Create header file
    NSString* headerFile = [factoryClassName stringByAppendingPathExtension:@"h"];
    printf("\tGenerating %s...", [headerFile UTF8String]);
    __block NSString* imports = @"//";
    imports = [imports stringByAppendingArray:@[@"//",headerFile] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"cblmodelgenerator"] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"\n"] joinedByString:@"" terminateWith:nil];
    imports = [imports stringByAppendingString:@"\n#import <CouchbaseLite/CouchbaseLite.h>"];
    
    NSString* interface = [@[@"@interface", factoryClassName, @": NSObject"] componentsJoinedByString:@" "];
    interface = [interface stringByAppendingString:@"\n\n+ (void)registerModelWithCBLModelFactory;"];
    
    NSString* output = [@[imports, interface, @"@end"] componentsJoinedByString:@"\n\n"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* headerFilePath = [self.outputPath stringByAppendingPathComponent:headerFile];
    [fileManager removeItemAtPath:headerFilePath error:nil];
    [fileManager createFileAtPath:headerFilePath contents:[output dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    printf("done\n");
    
    // Create source file
    NSString* sourceFile = [factoryClassName stringByAppendingPathExtension:@"m"];
    printf("\tGenerating %s...", [sourceFile UTF8String]);
    imports = @"//";
    imports = [imports stringByAppendingArray:@[@"//",sourceFile] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"cblmodelgenerator"] joinedByString:@"  " terminateWith:nil];
    imports = [imports stringByAppendingArray:@[@"//",@"\n"] joinedByString:@"" terminateWith:nil];
    imports = [imports stringByAppendingFormat:@"\n#import \"%@\"", headerFile];
    
    __block NSString* implementation = [@[@"@implementation", factoryClassName] componentsJoinedByString:@" "];
    implementation = [implementation stringByAppendingString:@"\n\n+ (void)registerModelWithCBLModelFactory {\n"];
    [self.entities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CBLEntity* entity = obj;
        if(entity.isDynamic) {
            // These are CBLModels
            implementation = [implementation stringByAppendingFormat:@"\t[[CBLModelFactory sharedInstance] registerClass:[%@ class] forDocumentType:NSStringFromClass([%@ class])];\n", entity.className, entity.className];
            imports = [imports stringByAppendingFormat:@"\n#import \"%@.h\"", entity.className];
        }
    }];
    implementation = [implementation stringByAppendingString:@"}"];
    
    output = [@[imports, implementation, @"@end"] componentsJoinedByString:@"\n\n"];
    NSString* sourceFilePath = [self.outputPath stringByAppendingPathComponent:sourceFile];
    [fileManager removeItemAtPath:sourceFilePath error:nil];
    [fileManager createFileAtPath:sourceFilePath contents:[output dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    printf("done\n");
}

@end
