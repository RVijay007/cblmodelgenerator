### BACKGROUND

This is a command line interface (CLI) to generate Couchbase Lite models from a Core Data file.

### INSTALLATION

1.  Clone the repository to your local drive

### USAGE

```cblmodelgenerator /path/to/xcdatamodeld [/path/to/modeloutputdirectory]```

Make sure your Core Data Model ```.xcdatamodeld``` is NOT included in any targets for your app as the file will be invalid in many cases.

#### Attribute Type Conversions

Use attribute types for normal properties that store primitives and generic foundation objects.

Integer 16/32/64 - int
Boolean - bool
Float - float
Double - double
Decimal - NSDecimalNumber
String - NSString
Date - NSDate
Binary Data - NSData
Transformable NOT supported. Will error.

#### Relationships

Create new relationships anytime you want to link a model/nestedmodel to another model, or to make arrays/dictionaries.

The following 4 examples illustrate all the ways to use relationships:

**Desired Output:** @property (nonatomic, strong) *ModelObject\** object;
Relationship name: object
Relationship type: To One
User Info <key,value>: <itemClass, ModelObject>

