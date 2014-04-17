### BACKGROUND

This is a command line interface (CLI) to generate Couchbase Lite models from a Core Data model file, i.e. ```..xcdatamodeld```.

### INSTALLATION

1.  Clone the repository to your local drive
2.  Select Archive from the ```Product``` menu in XCode.
3.  Right-click on the cblmodelgenerator archive in the Organizer and click "Show in Finder"
4.  Right-click on cblmodelgenerator*.xcarchive in Finder and click "Show Package Contents"
5.  Under ```Products/usr/local/bin```, locate cblmodelgenerator and copy this file to any directory in your terminal path, e.g. ```/usr/local/bin```

### USAGE

```cblmodelgenerator /path/to/xcdatamodeld [/path/to/modeloutputdirectory]```

Make sure your Core Data Model ```.xcdatamodeld``` is NOT included in any targets for your app as the file will be invalid in many cases.

### Core Data Model File Rules

You must adhere to these rules in order for the cblmodelgenerator to correctly generate header/source files for you. Since NoSQL supports more types of data than CoreData, we utilize specific conventions to direct the generator to create the desired syntax.

#### Attribute Type Conversions

Use attribute types for normal properties that store primitives and generic foundation objects.

| Core Data Attribute Type | Property Attribute Type |
|--------------------------|:-----------------------:|
| Integer 16/32/64         |         int             |
| Boolean                  |         bool            |
| Float                    |         float           |
| Double                   |         double          |
| Decimal                  |         NSDecimalNumber |
| String                   |         NSString        |
| Date                     |         NSDate          |
| Binary Data              |         NSData          |
| Transformable            |         UNSUPPORTED     |

Transformable attributes are not supported. This will throw an error.

#### Relationships

Create new relationships anytime you want to link a model/nestedmodel to another model, or to make arrays/dictionaries. JSON-compatible objects include ```NSString``` and ```NSNumber```. Non-JSON compatible objects include ```NSData```, ```NSDate```, and ```NSDecimalNumber```. ```ModelObject``` refers to another entity in your CoreData model. The following examples illustrate all the ways to use relationships:

**Desired Output:** ```@property (nonatomic, strong) ModelObject* object;```
- Relationship Name: ```object```
- Relationship Type: ```To One```
- User Info \<key,value\>: ```<itemClass, ModelObject>```

**Desired Output:** ```@property (nonatomic, strong) NSArray* object;```       *// An array of JSON-compatible objects*
- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [checked]```
- User Info \<key,value\>: ```empty```

**Desired Output:** ```@property (nonatomic, strong) NSArray* object;```        *// An array of ModelObjects or non-JSON objects*
- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [checked]```
- User Info \<key,value\>: ```<itemClass, ModelObject or non-JSON object>```
 
**Desired Output:** ```@property (nonatomic, strong) NSDictionary* object;```   *// A dictionary of JSON-compatible objects*
- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [UNchecked]```
- User Info \<key,value\>: ```empty```

**Desired Output:** ```@property (nonatomic, strong) NSDictionary* object;```   *// A dictionary of ModelObjects or non-JSON objects*
- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [UNchecked]```
- User Info \<key,value\>: ```<itemClass, ModelObject or non-JSON object>```