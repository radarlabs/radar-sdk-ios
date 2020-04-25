export interface TypeMatchers<T> {
  id: () => T;
  NSObject: () => T;
  BOOL: () => T;
  NSInteger: () => T;
  NSUInteger: () => T;
  double: () => T;
  float: () => T;
  unmatchedType: () => T;
}

export function matchType<T>(matchers: TypeMatchers<T>, type: ObjCType): T {
  const typeName = type.name;
  if (typeName === 'id') {
    return matchers.id();
  } else if (typeName === 'NSObject') {
    return matchers.NSObject();
  } else if (typeName === 'BOOL') {
    return matchers.BOOL();
  } else if (typeName === 'NSInteger') {
    return matchers.NSInteger();
  } else if (typeName === 'NSUInteger') {
    return matchers.NSUInteger();
  } else if (typeName === 'double') {
    return matchers.double();
  } else if (typeName === 'float') {
    return matchers.float();
  } else {
    return matchers.unmatchedType();
  }
  // return matchTypeName(matchers, type.name);
}

/** Like matchType but allows you to pass a type name instead of an ObjC.Type. */
// export function matchTypeName<T>(
//   matchers: TypeMatchers<T>,
//   typeName: string,
// ): T {
//   if (typeName === 'id') {
//     return matchers.id();
//   } else if (typeName === 'NSObject') {
//     return matchers.NSObject();
//   } else if (typeName === 'BOOL') {
//     return matchers.BOOL();
//   } else if (typeName === 'NSInteger') {
//     return matchers.NSInteger();
//   } else if (typeName === 'NSUInteger') {
//     return matchers.NSUInteger();
//   } else if (typeName === 'double') {
//     return matchers.double();
//   } else if (typeName === 'float') {
//     return matchers.float();
//   } else {
//     return matchers.unmatchedType();
//   }
// }

enum ClassNullability {
  default,
  assumeNonnull,
}

interface Error {
  reason: string;
}

function Error(reason: string): Error {
  return { reason: reason};
}

 enum FileType {
  ObjectiveC,
  ObjectiveCPlusPlus,
}

 interface Protocol {
  name: string;
}

 interface Import {
  file: string;
  isPublic: boolean;
  library: string | null;
  // guard with #ifdef __cplusplus
  requiresCPlusPlus: boolean;
}

 enum KeywordArgumentModifierType {
  nonnull,
  nullable,
  noescape,
  unsafe_unretained,
}

class KeywordArgumentModifier {
  private modifierType: KeywordArgumentModifierType;
  constructor(type: KeywordArgumentModifierType) {
    this.modifierType = type;
  }

  static Nonnull() {
    return new KeywordArgumentModifier(KeywordArgumentModifierType.nonnull);
  }

  static Nullable() {
    return new KeywordArgumentModifier(KeywordArgumentModifierType.nullable);
  }

  static Noescape() {
    return new KeywordArgumentModifier(KeywordArgumentModifierType.noescape);
  }

  static UnsafeUnretained() {
    return new KeywordArgumentModifier(
      KeywordArgumentModifierType.unsafe_unretained,
    );
  }

  match<T>(
    nonnull: () => T,
    nullable: () => T,
    noescape: () => T,
    unsafe_unretained: () => T,
  ) {
    switch (this.modifierType) {
      case KeywordArgumentModifierType.nonnull:
        return nonnull();
      case KeywordArgumentModifierType.nullable:
        return nullable();
      case KeywordArgumentModifierType.noescape:
        return noescape();
      case KeywordArgumentModifierType.unsafe_unretained:
        return unsafe_unretained();
    }
  }
}

interface KeywordArgument {
  name: string;
  modifiers: KeywordArgumentModifier[];
  type: ObjCType;
}

interface Keyword {
  argument: KeywordArgument | null;
  name: string;
}

interface ObjCType {
  name: string;
  reference: string;
}

interface ReturnType {
  type: ObjCType | null;
  modifiers: KeywordArgumentModifier[];
}

interface Comment {
  content: string;
}

 interface Method {
  preprocessors: any;
  belongsToProtocol: string | null;
  code: string[] | null;
  comments: Comment[];
  compilerAttributes: string[];
  keywords: Keyword[];
  returnType: ReturnType;
}

 interface TypeLookup {
  name: string;
  library: string | null;
  file: string | null;
  canForwardDeclare: boolean;
}

interface Annotation {
  properties: {[name: string]: string};
}

export interface AnnotationMap {
  [name: string]: Annotation[];
}

enum NullabilityType {
  inherited,
  nonnull,
  nullable,
}

class Nullability {
  private nullabilityType: NullabilityType;

  constructor(type: NullabilityType) {
    this.nullabilityType = type;
  }

  static Inherited() {
    return new Nullability(NullabilityType.inherited);
  }

  static Nonnull() {
    return new Nullability(NullabilityType.nonnull);
  }

  static Nullable() {
    return new Nullability(NullabilityType.nullable);
  }

  match<T>(inherited: () => T, nonnull: () => T, nullable: () => T) {
    switch (this.nullabilityType) {
      case NullabilityType.inherited:
        return inherited();
      case NullabilityType.nonnull:
        return nonnull();
      case NullabilityType.nullable:
        return nullable();
    }
  }
}

interface ReferencedGenericType {
  name: string;
  conformingProtocol: string | null;
  referencedGenericTypes: ReferencedGenericType[];
}

interface AttributeType {
  fileTypeIsDefinedIn: string | null;
  libraryTypeIsDefinedIn: string | null;
  name: string;
  reference: string;
  underlyingType: string | null;
  conformingProtocol: string | null;
  referencedGenericTypes: ReferencedGenericType[];
}

interface Attribute {
  annotations: AnnotationMap;
  comments: string[];
  name: string;
  nullability: Nullability;
  type: AttributeType;
}

interface Type {
  annotations: AnnotationMap;
  attributes: Attribute[];
  comments: string[];
  excludes: string[];
  includes: string[];
  libraryName: string | null;
  typeLookups: TypeLookup[];
  typeName: string;
}

interface Plugin {
  additionalFiles: (objectType: Type) => any;
  transformBaseFile: (objectType: Type, baseFile: any) => any;
  additionalTypes: (objectType: Type) => Type[];
  attributes: (objectType: Type) => Attribute[];
  classMethods: (objectType: Type) => Method[];
  transformFileRequest: (
    writeRequest: any,
  ) => any;
  fileType: (objectType: Type) => FileType | null;
  forwardDeclarations: (objectType: Type) => any;
  functions: (objectType: Type) => any;
  headerComments: (objectType: Type) => any;
  imports: (objectType: Type) => Import[];
  implementedProtocols: (objectType: Type) => Protocol[];
  instanceMethods: (objectType: Type) => Method[];
  instanceVariables?: (objectType: Type) => any;
  macros: (objectType: Type) => any;
  properties: (objectType: Type) => any;
  requiredIncludesToRun: string[];
  staticConstants: (objectType: Type) => any;
  validationErrors: (objectType: Type) => Error[];
  nullability: (objectType: Type) => ClassNullability | null;
  subclassingRestricted: (objectType: Type) => boolean;
  structs?: (objectType: Type) => any;
  baseClass?: (objectType: Type) => any;
  blockTypes?: (algebraicType: Type) => any;
}

// functions

function typeForUnderlyingType(underlyingType: string): ObjCType {
  return {
    name: underlyingType,
    reference: underlyingType === 'NSObject' ? 'NSObject*' : underlyingType,
  };
}

function match<T, U>(
  just: (t: T) => U,
  nothing: () => U,
  maybe: T | null | undefined,
): U {
  if (maybe == null) {
    return nothing();
  } else {
    return just(maybe);
  }
}

function computeTypeOfAttribute(
  attribute: Attribute,
): ObjCType {
  return match(
    typeForUnderlyingType,
    function(): ObjCType {
      return {
        name: attribute.type.name,
        reference: attribute.type.reference,
      };
    },
    attribute.type.underlyingType,
  );
}
 
 function dictionaryWrappingAmpersand(attributeName: string):string {
   return "@(" + attributeName + ")";
 }

 const isRadarClass = (name: string) => (name.indexOf('Radar') !== -1);

 function referencedGenericTypesIncludesRadarClass(genericType: ReferencedGenericType): boolean {
   if (isRadarClass(genericType.name)) {
     return true;
   }

   for (const subType of genericType.referencedGenericTypes) {
     if (referencedGenericTypesIncludesRadarClass(subType)) {
       return true;
     }
   }
   return false;
 }

 function isAttributeTypeUnsupported(attribute: Attribute): boolean {
  const type = computeTypeOfAttribute(attribute);
  return matchType({
    id: () => false,
    BOOL: () => false,
    NSInteger: () => false,
    NSUInteger: () => false,
    double: () => false,
    float: () => false,
    NSObject: () => {
      const typeName = attribute.type.name;
      if (typeName.indexOf('NSMutable') !== -1) {
        return true;
      }
      if (typeName === 'NSSet') {
        return true;
      }
      if (typeName === 'NSArray') {
        for (const genericType of attribute.type.referencedGenericTypes) {
          if (isRadarClass(genericType.name)) {
            return false; // we support NSArray<RadarXX *> * 
          } else if (referencedGenericTypesIncludesRadarClass(genericType)) {
            return true;
          }
        }
        return false;
      }

      if (typeName === 'NSDictionary') {
        for (const genericType of attribute.type.referencedGenericTypes) {
          if (referencedGenericTypesIncludesRadarClass(genericType)) {
            return true;
          }
        }
        return false;
      }
      return false;
    },
    unmatchedType: () => true,
  }, type);
 }
 
 // from model to json
 function toDictAssignment(attribute:Attribute):string {
   const keyName = attribute.name;
   const ivar = '_' + keyName;
   const raw = 'dictionary[@"' + keyName + '"]';

   const type = computeTypeOfAttribute(attribute);

   const assignment = matchType({
     id: () => [`${raw} = ${ivar};`],
     BOOL: () => [`${raw} = ${dictionaryWrappingAmpersand(ivar)};`],
     NSInteger: () => [`${raw} = ${dictionaryWrappingAmpersand(ivar)};`],
     NSUInteger: () => [`${raw} = ${dictionaryWrappingAmpersand(ivar)};`],
     double: () => [`${raw} = ${dictionaryWrappingAmpersand(ivar)};`],
     float: () => [`${raw} = ${dictionaryWrappingAmpersand(ivar)};`],
     NSObject: () =>{
      const typeName = attribute.type.name;
      const defaultAssignment = [`${raw} = ${ivar};`];
      if (typeName === 'NSArray') {
        if (attribute.type.referencedGenericTypes.length > 0) {
          const genericName = attribute.type.referencedGenericTypes[0].name;
          if (isRadarClass(genericName)) {
            return [
              `${raw} = [${ivar} radar_mapObjectsUsingBlock:^id _Nullable(${genericName} * _Nonnull obj) {`,
              `return [obj dictionaryValue];`,
              `}];`
            ];
          }
        } 
        return defaultAssignment;
      } else if (typeName === 'NSDictionary') {
        // if (attribute.type.referencedGenericTypes.length > 1) {
        //   const genericName = attribute.type.referencedGenericTypes[1].name;
        //   if (isRadarClass(genericName)) {
        //     return [
        //       `${raw} = [${ivar} radar_mapObjectsUsingBlock:^id _Nullable(${genericName} * _Nonnull obj) {`,
        //       `return [obj dictionaryValue];`,
        //       `}];`
        //     ];
        //   }
        // } 
        return defaultAssignment;
      } else if (isRadarClass(typeName)) {
        return [`${raw} = [${ivar} dictionaryValue];`];
      } else {
        return defaultAssignment
      }
     },
     unmatchedType: () => []
   }, type);

   const withNullability = attribute.nullability.match(
     () => assignment,
     () => assignment,
     () => {
       return [
         `if (${ivar}) {`
       ].concat(assignment)
       .concat([
         '}',
       ]);
     });
     return withNullability.join(`\n`);
 }
 
 function instanceToJSONConverter(attributes:Attribute[]):string[] {
   const result = [
     'NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];'
   ].concat(attributes.map(toDictAssignment))
    .concat([
     'return [dictionary copy];',
   ]);
   return result;
 }
 
 function instanceToJSONMethod(attributes:Attribute[]):Method {
   return {
     preprocessors: [],
     belongsToProtocol: 'RadarJSONCoding',
     code: instanceToJSONConverter(attributes),
     comments:[{
      content: '// Convert to JSON object (either an dictionary or array).'
      },
     ],
     compilerAttributes:[],
     keywords: [
       {
         name: 'dictionaryValue',
         argument: null
       }
     ],
     returnType: {
       type: ({
         name: 'NSDictionary *',
         reference: 'NSDictionary *'
       }),
       modifiers: []
     }
   };
 }
 
 // from json to model
 function toIvarAssignment(attribute:Attribute):string {
   const keyName = attribute.name;
   const ivar = '_' + keyName;
   const raw = 'dictionary[@"' + keyName + '"]';

   const type = computeTypeOfAttribute(attribute);

   const assignment = matchType({
     id: () => {
       return [
         `if (${raw}) {`,
         `${ivar} = ${raw};`,
         '}',
       ];
     },
     BOOL: () => {
       return [
         `if (${raw} && [${raw} isKindOfClass:[NSNumber class]]) {`,
         `${ivar} = [${raw} boolValue];`,
         `}`,
       ];
     },
     NSInteger: () => {
      return [
        `if (${raw} && [${raw} isKindOfClass:[NSNumber class]]) {`,
        `${ivar} = [${raw} integerValue];`,
        `}`,
      ];
     },
     NSUInteger: () => {
      return [
        `if (${raw} && [${raw} isKindOfClass:[NSNumber class]]) {`,
        `${ivar} = [${raw} unsignedIntegerValue];`,
        `}`,
      ];
     },
     double: () => {
      return [
        `if (${raw} && [${raw} isKindOfClass:[NSNumber class]]) {`,
        `${ivar} = [${raw} doubleValue];`,
        `}`,
      ];
     },
     float: () => {
      return [
        `if (${raw} && [${raw} isKindOfClass:[NSNumber class]]) {`,
        `${ivar} = [${raw} floatValue];`,
        `}`,
      ];
     },
     NSObject: () => {
      const typeName = attribute.type.name;
      const defaultAssignmentLine = `${ivar} = (${typeName} *)${raw};`
       if (typeName === 'NSArray') {
        let ivarAssignmentLine = defaultAssignmentLine;
        if (attribute.type.referencedGenericTypes.length > 0) {
          const genericName = attribute.type.referencedGenericTypes[0].name;
          if (isRadarClass(genericName)) {
            ivarAssignmentLine = `${ivar} = [${genericName} fromObjectArray:${raw}];`;
          }
        } 
        return [
          `if (${raw} && [${raw} isKindOfClass:[NSArray class]]) {`,
          ivarAssignmentLine,
          `}`,
         ];
       } else if (typeName === 'NSDictionary') {
        return [
          `if (${raw} && [${raw} isKindOfClass:[${typeName} class]]) {`,
          defaultAssignmentLine,
          `}`,
         ];
        // if (attribute.type.referencedGenericTypes.length > 1) {
        //   const genericName = attribute.type.referencedGenericTypes[1].name;
        //   if (isRadarClass(genericName)) {
        //     ivarAssignmentLine = [
        //       `${ivar} = [(NSDictionary *)${raw} radar_mapObjectsUsingBlock:^id _Nullable(id  _Nonnull obj) {`,
        //       `return [[${genericName} alloc] initWithObject:obj];`,
        //       `}];`
        //     ].join('\n');
        //   }
        // }
       } else if (typeName === 'NSNumber' || typeName === 'NSString') {
         return [
          `if (${raw} && [${raw} isKindOfClass:[${typeName} class]]) {`,
          defaultAssignmentLine,
          `}`,
         ];
       } else if (isRadarClass(typeName)) {
         return [
           `if (${raw} && [${raw} isKindOfClass:[NSDictionary class]]) {`,
           `${ivar} = [[${typeName} alloc] initWithObject:${raw}];`,
           `}`,
          ];
       } else {
        return [
          `if (${raw}) {`,
          defaultAssignmentLine,
          `}`,
         ];
       }
     },
     unmatchedType: () => [],
   }, type);

   if (type.name !== 'NSObject') {
     return assignment.join('\n')
   }

   const nullabilityCheck = attribute.nullability.match(
    () => {
      // this is assumeNonnull
      return [
        `if (!${ivar}) {`,
        `self = nil;`,
        `return self;`,
        '}',
     ];
    }, 
    () => {
        return [
            `if (!${ivar}) {`,
            `self = nil;`,
            `return self;`,
            '}',
        ];
    },
    () => {
        return null;
    });

    if (nullabilityCheck) {
      return assignment.concat(nullabilityCheck).join('\n');
    } else {
      return assignment.join('\n');
    }
 }
 
 function JSONToInstanceInitializer(objectType: Type):string[] {
  const attributes = objectType.attributes;
  const result = [
     'if ((self = [super init])) {'
   ].concat(attributes.map(toIvarAssignment))
    .concat([
     '}',
     'return self;'
   ]);

   const finalResult = [
       'if (!object || ![object isKindOfClass:[NSDictionary class]]) {',
       'return nil;',
       '}',
       'NSDictionary *dictionary = (NSDictionary *)object;'
   ].concat(result);
   return finalResult;
 }
 
 function JSONToInstanceMethod(objectType: Type):Method {
   return {
     preprocessors:[],
     belongsToProtocol: 'RadarJSONCoding',
     code: JSONToInstanceInitializer(objectType),
     comments:[{
       content: '// Initializer from JSON Object.'
     },
       ],
     compilerAttributes: ['NS_DESIGNATED_INITIALIZER'],
     keywords: [
       {
         name: 'initWithObject',
         argument: ({
           name: 'object',
           modifiers: [KeywordArgumentModifier.Nullable()],
           type: {
             name: 'id',
             reference: 'id'
           }
         })
       }
     ],
     returnType: {
       type: ({
         name: 'instancetype',
         reference: 'instancetype'
       }),
       modifiers: [KeywordArgumentModifier.Nullable()]
     }
   };
 }

 // from json array to model array

 function JSONArrayToInstanceCode(objectType: Type):string[] {
  return `
  if (!objectArray || ![objectArray isKindOfClass:[NSArray class]]) {
    return nil;
  } 
  
  NSMutableArray<${objectType.typeName} *> *array = [NSMutableArray array];
  for (id object in (NSArray *)objectArray) {
      ${objectType.typeName} *value = [[${objectType.typeName} alloc] initWithObject:object];
      if (!value) {
          return nil;
      }
      [array addObject:value];
  }

  return [array copy];
  `.split('\n');
 }

 function  JSONArrayToInstanceMethod(objectType: Type):Method {
  return {
    preprocessors:[],
    belongsToProtocol: 'RadarJSONCoding',
    code: JSONArrayToInstanceCode(objectType),
    comments:[],
    compilerAttributes: [],
    keywords: [
      {
        name: 'fromObjectArray',
        argument: ({
          name: 'objectArray',
          modifiers: [KeywordArgumentModifier.Nullable()],
          type: {
            name: 'id',
            reference: 'id'
          }
        })
      }
    ],
    returnType: {
      type: ({
        name: `NSArray<${objectType.typeName} *> *`,
        reference: `NSArray<${objectType.typeName} *> *`,
      }),
      modifiers: [KeywordArgumentModifier.Nullable()]
    }
  };
} 

function valueAttributeToUnsupportedTypeError(objectType, attribute) {
   return match(function (underlyingType) {
       return Error('The RadarJSONCoding plugin does not know how to decode and encode the backing type "' + underlyingType + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
   }, function () {
       return Error('The RadarJSONCoding plugin does not know how to decode and encode the type "' + attribute.type.name + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
   }, attribute.type.underlyingType);
 }
 
 export function createPlugin():Plugin {
   return {
     additionalFiles: function(objectType:Type) {
       return [];
     },
     transformBaseFile: function(
      objectType: Type,
      baseFile: any,
    ): any {
      return baseFile;
    },
     additionalTypes: function(objectType:Type):Type[] {
       return [];
     },
     attributes: function(objectType:Type):Attribute[] {
      return [];
    },
     classMethods: function(objectType:Type):Method[] {
      return [JSONArrayToInstanceMethod(objectType)];
     },
     transformFileRequest: function(
      request: any,
    ) {
      return request;
    },
     fileType: function(objectType:Type) {
       return null;
     },
     forwardDeclarations: function(objectType:Type):any {
       return [];
     },
     functions: function(objectType:Type):any {
       return [];
     },
     headerComments: function(objectType:Type):any {
       return [];
     },
     imports: function(objectType:Type):Import[] {
      return [
        {
          file: 'RadarJSONCoding.h',
          isPublic: true,
          requiresCPlusPlus: false,
          library: null,
        },
        {
          file: 'RadarCollectionAdditions.h',
          isPublic: false,
          requiresCPlusPlus: false,
          library: null,
        },
      ];
    },
     implementedProtocols: function(objectType:Type):Protocol[] {
      return [
        {
          name: 'RadarJSONCoding',
        },
      ];
     },
     instanceMethods: function(objectType:Type):Method[] {
       return [instanceToJSONMethod(objectType.attributes),
               JSONToInstanceMethod(objectType)];
     },
     macros: function(valueType: Type){
      return [];
    },
    properties: function(objectType: Type){
      return [];
    },
     requiredIncludesToRun:['RadarJSONCoding'],
     staticConstants: function(objectType:Type) {
       return [];
     },
     validationErrors: function(objectType:Type):Error[] {
       const unsupportedTypeErrors: Error[] = [];
       const unsupportedAttributes = objectType.attributes.filter(isAttributeTypeUnsupported);
       for (const attribute of unsupportedAttributes) {
         const error = valueAttributeToUnsupportedTypeError(objectType, attribute);
         unsupportedTypeErrors.push(error);
       }
       return unsupportedTypeErrors;
     },
     nullability: function(objectType:Type) {
       return null;
     },
     subclassingRestricted: function(objectType: Type): boolean {
      return false;
    },
   };
 }