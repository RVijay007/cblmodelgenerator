## BACKGROUND

This is a command line interface (CLI) to generate Couchbase Lite models from a Core Data model file, i.e. ```*.xcdatamodeld```.

## INSTALLATION

1.  Clone the repository to your local drive
2.  Select Archive from the ```Product``` menu in XCode.
3.  Right-click on the cblmodelgenerator archive in the Organizer and click "Show in Finder"
4.  Right-click on cblmodelgenerator*.xcarchive in Finder and click "Show Package Contents"
5.  Under ```Products/usr/local/bin```, locate cblmodelgenerator and copy this file to any directory in your terminal path, e.g. ```/usr/local/bin```

## USAGE

```cblmodelgenerator /path/to/xcdatamodeld [/path/to/modeloutputdirectory]```

This tool will create a generated/ directory that will contain all your model entities. This is so that it is easy to remove/add the reference during model refreshes.

## Core Data Model File Rules

You must adhere to these rules in order for the cblmodelgenerator to correctly generate header/source files for you. Since NoSQL supports more types of data than CoreData, we utilize specific conventions to direct the generator to create the desired syntax.

JSON-compatible objects include ```NSString``` and ```NSNumber```. Non-JSON compatible objects include ```NSData```, ```NSDate```, and ```NSDecimalNumber```.

### Required classes in your model

You have two alternatives to specify that your classes inherit from CBLModels or CBLNestedModels. You should pick one based on what you prefer for readability when looking at your Core Data model.

#### Method 1

Starting with a blank Core Data model file, you can create an Entity named ```CBLModel```. It will not be generated in code however since CouchbaseLite already has this. Any subsequent CBLModel entities you create would set the ```CBLModel``` entity as its parent.

If you decide to use my ```CBLNestedModel``` class (from my fork of couchbase-lite-ios), then you can also create an entity named ```CBLNestedModel``` and set it as the parent for any entities that should derive from that class. Similar to ```CBLModel``, this entity will also NOT be generated when you run the CLI since it is included with the CouchbaseLite framework.

Essentially, all your entities would have a parent, either CBLModel, CBLNestedModel, or derivative entities that you create yourself.

#### Method 2

If you prefer not to have to create the CBLModel or CBLNestedModel entities on your Core Data model, then an alternative way to specify your class as inheriting from CBLModel is to declare the entity as an ```Abstract Entity```. Classes that do not declare themselves as an ```Abstract Entity``` will derive from CBLNestedModel. 

If the class derives from another entity in your model, this parameter is ignored and the tool will automatically determine whether the class is derived from CBLModel or CBLNestedModel. Therefore, this is only required for entities that do not specify any parent entity.

### Attribute Type Conversions

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
| Transformable            |         *Object*        |

Transformable attributes should be thought of as "relationships" to other objects not represented in your CoreData model file. For example, you may want an NSArray/NSDictionary of strings (JSON-compatible), or dates (non-JSON compatible). If you select Transformable, you must specify whether it is an NSArray or NSDictionary in the second ```Attribute Type``` name field. If it stores non-JSON compatible objects, then you must additionally specify the following \<key=itemClass,value\> under User Info for the attribute.

**Desired Output:** ```@property (nonatomic, strong) NSArray* object;```       *// An array of JSON-compatible objects*

- Attribute Name: ```object```
- Attribute Type: ```Transformable```
- Attribute Type Name: ```NSArray```
- User Info \<key,value\>: ```empty``` if JSON-compatible; ```<itemClass, ClassName>``` if not JSON-compatible

**Desired Output:** ```@property (nonatomic, strong) NSDictionary* object;```   *// A dictionary of JSON-compatible objects*

- Attribute Name: ```object```
- Attribute Type: ```Transformable```
- Attribute Type Name: ```NSDictionary```
- User Info \<key,value\>: ```empty``` if JSON-compatible; ```<itemClass, ClassName>``` if not JSON-compatible


### Relationships

Create new relationships anytime you want to link a model/nestedmodel to another model, or to make arrays/dictionaries.  ```ModelObject``` refers to another entity in your CoreData model. The following examples illustrate all the ways to use relationships:

**Desired Output:** ```@property (nonatomic, strong) ModelObject* object;```

- Relationship Name: ```object```
- Relationship Type: ```To One```

**Desired Output:** ```@property (nonatomic, strong) NSArray* object;```        *// An array of ModelObjects*

- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [checked]```
 
**Desired Output:** ```@property (nonatomic, strong) NSDictionary* object;```   *// A dictionary of ModelObjects*

- Relationship Name: ```object```
- Relationship Type: ```To Many```
- Relationship Arrangement: ```Ordered [UNchecked]```

## Model Factory

By default, this tool will set the CBLModel ```type``` parameter to be the class name of the entity if you use the initializer ```initWithNewDocumentInDatabase```. You should strive to always use this designated initializer when creating new documents in your database instead of making a new CBLDocument and then attaching a model to it.

In addition, it generates separate header/source files called *ModelName*ModelFactory, which has one method ```+ (void)registerModelWithCBLModelFactory;```. You can call this class method from your AppDelegate, and all your models will automatically be registered with the CBLModelFactory to do dynamic subclassing. Please refer to CouchbaseLite documentation for more details on the CBLModelFactory.

## XCode Project Settings

In CouchbaseLite, you may find yourself setting up many one-way relationships since you can always use views to filter data other ways. Keeping one-way relationships significantly improves readability of your Core Data model, but Core Data itself does not recommend using these. In order to prevent users from setting up one-way relationships, XCode will throw warnings notifying the developer of one-way relationships in the Core Data Model file.

Since we are not using the underlying CoreData framework, we recommend not adding your model file to your target build and turning off warnings for one-way relationships. You can do this by following the steps below:

- Click your ```*.xcdatamodeld``` file in your Project Navigator, and then, in the File Inspector on the right (icon that looks like a document), UNCHECK everything under ```Target Membership```. This removes the data model from being built or included with our app.
- Click on your Project in the Project Navigator to display the settings, and make sure that the dropdown selects your Project, and not any of your Targets (By default, it selects your Target, so you'll most likely need to change this. It is the top left hand corner dropdown of your Settings page).
- Click on ```Build Settings``` and search for ```MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS```. The default value is ```NO```; change this to ```YES```.
- You may need to clean your project, close XCode, reopen your project, and build to see the warnings disappear.
