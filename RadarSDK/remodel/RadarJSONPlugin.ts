export interface TypeMatchers<T> {
  id: () => T;
  NSObject: () => T;
  BOOL: () => T;
  NSInteger: () => T;
  NSUInteger: () => T;
  double: () => T;
  float: () => T;
  CGFloat: () => T;
  NSTimeInterval: () => T;
  uintptr_t: () => T;
  uint32_t: () => T;
  uint64_t: () => T;
  int32_t: () => T;
  int64_t: () => T;
  SEL: () => T;
  NSRange: () => T;
  CGRect: () => T;
  CGPoint: () => T;
  CGSize: () => T;
  UIEdgeInsets: () => T;
  Class: () => T;
  dispatch_block_t: () => T;
  unmatchedType: () => T;
}

export function matchType<T>(matchers: TypeMatchers<T>, type: ObjCType): T {
  return matchTypeName(matchers, type.name);
}

/** Like matchType but allows you to pass a type name instead of an ObjC.Type. */
export function matchTypeName<T>(
  matchers: TypeMatchers<T>,
  typeName: string,
): T {
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
  } else if (typeName === 'CGFloat') {
    return matchers.CGFloat();
  } else if (typeName === 'NSTimeInterval') {
    return matchers.NSTimeInterval();
  } else if (typeName === 'uintptr_t') {
    return matchers.uintptr_t();
  } else if (typeName === 'uint32_t') {
    return matchers.uint32_t();
  } else if (typeName === 'uint64_t') {
    return matchers.uint64_t();
  } else if (typeName === 'int32_t') {
    return matchers.int32_t();
  } else if (typeName === 'int64_t') {
    return matchers.int64_t();
  } else if (typeName === 'SEL') {
    return matchers.SEL();
  } else if (typeName === 'NSRange') {
    return matchers.NSRange();
  } else if (typeName === 'CGRect') {
    return matchers.CGRect();
  } else if (typeName === 'CGPoint') {
    return matchers.CGPoint();
  } else if (typeName === 'CGSize') {
    return matchers.CGSize();
  } else if (typeName === 'UIEdgeInsets') {
    return matchers.UIEdgeInsets();
  } else if (typeName === 'Class') {
    return matchers.Class();
  } else if (typeName === 'dispatch_block_t') {
    return matchers.dispatch_block_t();
  } else {
    return matchers.unmatchedType();
  }
}

enum ClassNullability {
  default,
  assumeNonnull,
}

interface Error {
  reason: string;
}

function Error(reason: string) {
  return {reason: reason};
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

function stringContainingSpaces(spaces: number): string {
  var str = '';
  for (var i = 0; i < spaces; i++) {
    str += ' ';
  }
  return str;
}

function indentFunc(spaces: number, str: string): string {
  if (str !== '') {
    return stringContainingSpaces(spaces) + str;
  } else {
    return str;
  }
}

function strIndent(spaces: number): (str: string) => string {
  return str => indentFunc(spaces, str);
}

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

function pApplyf2<T, U, V>(val: T, f: (a: T, b: U) => V): (b: U) => V {
  return function(b: U): V {
    return f(val, b);
  };
}

const noChange = (attributeName: string) => attributeName;
 
 function dictionaryWrappingAmpersand(attributeName: string):string {
   return "@(" + attributeName + ")";
 }
 
 
 function dictionaryUnwrappingByKeyword(unwrappingKeyword: string): (attributeName: string) => string {
   return function(attributeName: string): string {
     return "[" + attributeName + " " + unwrappingKeyword + "]"
   };
 }
 
 function dictionaryParsingFunction(attribute:Attribute) {
   const iVarString = '_' + attribute.name;
   const type = computeTypeOfAttribute(attribute);
   const defaultParsingFunction =  {
     keyFromModelGenerator: noChange, // model --> dict
     keyToModelGenerator: noChange, // dict --> model
   };
 
   return matchType({
     id: function() {
       return defaultParsingFunction;
     },
     NSObject: function() {
       const typeName = attribute.type.name;
       const keyToModelGenerator = (val) => {
         if (typeName.startsWith('Radar') || typeName === 'NSArray') {
          return `[[${typeName} alloc] initWithRadarJSONObject:${val}]`;
         } else {
           return `(${typeName} *)${val}`;
         }
       }

       const keyFromModelGenerator = (val) => {
        if (typeName.startsWith('Radar') || typeName === 'NSArray') {
          return `[_${attribute.name} toRadarJSONObject]`;
         } else {
           return val;
         }
       }

       return { 
        keyFromModelGenerator,
        keyToModelGenerator,
      };
     },
     BOOL: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("boolValue"),
       };
     },
     NSInteger: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("integerValue"),
       };
     },
     NSUInteger: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("unsignedIntegerValue"),
       };
     },
     double: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("doubleValue"),
       };
     },
     float: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("floatValue"),
       };
     },
     CGFloat: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("floatValue"),
       };
     },
     NSTimeInterval: function() {
       return {
         keyFromModelGenerator: dictionaryWrappingAmpersand,
         keyToModelGenerator: dictionaryUnwrappingByKeyword("doubleValue"),
       };
     },
     uintptr_t: function() {
       return null;
     },
     uint32_t: function() {
       return null;
     },
     uint64_t: function() {
       return null;
     },
     int32_t: function() {
       return null;
     },
     int64_t: function() {
       return null;
     },
     SEL: function() {
       return null;
     },
     NSRange: function() {
       return null;
     },
     CGRect: function() {
       return null;
     },
     CGPoint: function() {
       return null;
     },
     CGSize: function() {
       return null;
     },
     UIEdgeInsets: function() {
       return null;
     },
     Class: function() {
       return null;
     },
     dispatch_block_t: function() {
       return null;
     },
     unmatchedType: function() {
       return null;
     }
   }, type);
 }
 
 function toIvarKeyValuePair(attribute:Attribute):string {
   const iVar = '_' + attribute.name;
   const parsingFunction = dictionaryParsingFunction(attribute);
   let wrapped = iVar;
   if (parsingFunction) {
     wrapped = parsingFunction.keyFromModelGenerator(iVar);
   } 

   const keyName = attribute.name;

   return attribute.nullability.match(
     () => {
      return 'dict[@"' + keyName + '"] = ' + wrapped + ';' ;
     },
     () => {
      return 'dict[@"' + keyName + '"] = ' + wrapped + ';' ;
     }, // nonnull
     () => {
       return [
         `if (${iVar}) {`,
         strIndent(2)('dict[@"' + keyName + '"] = ' + wrapped + ';'),
         '}'
       ].join('\n');
     },
   );
 }
 
 function instanceToDictionaryConverter(attributes:Attribute[]):string[] {
   const result = [
     'NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];'
   ].concat(attributes.map(toIvarKeyValuePair))
    .concat([
     'return [dict copy];',
   ]);
   return result;
 }
 
 function instanceToDictionaryMethod(attributes:Attribute[]):Method {
   return {
     preprocessors: [],
     belongsToProtocol: 'RadarJSONCoding',
     code: instanceToDictionaryConverter(attributes),
     comments:[{
      content: '// Convert to JSON object (either an dictionary or array).'
      },
     ],
     compilerAttributes:[],
     keywords: [
       {
         name: 'toRadarJSONObject',
         argument: null
       }
     ],
     returnType: {
       type: ({
         name: 'id',
         reference: 'id'
       }),
       modifiers: []
     }
   };
 }
 
 function safeUnwrapDecodingStatement(parsingFunction, decodingStatement): string {
   let unwrapped = decodingStatement;
   if (parsingFunction) {
     unwrapped = parsingFunction.keyToModelGenerator(unwrapped);
   }
   return unwrapped;
 }
 
 function toIvarAssignment(supportsValueSemantics:boolean, attribute:Attribute):string {
   const keyName = attribute.name;
   const raw = 'dictionary[@"' + keyName + '"]';
   const parsingFunction = dictionaryParsingFunction(attribute);
   const unwrapped = safeUnwrapDecodingStatement(parsingFunction, raw);
 
   let decoded = unwrapped;
 
//    const shouldCopy = ObjectSpecCodeUtils.shouldCopyIncomingValueForAttribute(supportsValueSemantics, attribute);
   decoded = decoded + ";";
   let res: string;
   return attribute.nullability.match(
       () => {
        return [
            `if (!${raw}) {`,
            strIndent(4)('return nil;'),
            '}',
            '_' + attribute.name + ' = ' + decoded
        ].join('\n');
       }, 
       () => {
           return [
               `if (!${raw}) {`,
               strIndent(4)('return nil;'),
               '}',
               '_' + attribute.name + ' = ' + decoded
           ].join('\n');
       }, // nonnull
       () => {
           return '_' + attribute.name + ' = ' + decoded;
       }); //nullable
 }
 
 function dictionaryToInstanceInitializer(attributes:Attribute[]):string[] {
   const result = [
     'if ((self = [super init])) {'
   ].concat(attributes.map(pApplyf2(true, toIvarAssignment)).map(strIndent(2)))
    .concat([
     '}',
     'return self;'
   ]);

   const finalResult = [
       'if (!object || ![object isKindOfClass:[NSDictionary class]]) {',
       strIndent(2)('return nil;'),
       '}',
       'NSDictionary *dictionary = (NSDictionary *)object;'
   ].concat(result);
   return finalResult;
 }
 
 function dictionaryToInstanceMethod(attributes:Attribute[]):Method {
   return {
     preprocessors:[],
     belongsToProtocol: 'RadarJSONCoding',
     code: dictionaryToInstanceInitializer(attributes),
     comments:[{
       content: '// Initializer from JSON Object.'
     },
       ],
     compilerAttributes: ['NS_DESIGNATED_INITIALIZER'],
     keywords: [
       {
         name: 'initWithRadarJSONObject',
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
 
 function doesValueAttributeContainAnUnsupportedType(attribute:Attribute) {
   return dictionaryParsingFunction(attribute) == null;
 }
 
 function valueAttributeToUnsupportedTypeError(objectType, attribute) {
   return match(function (underlyingType) {
       return Error('The JSONCoding plugin does not know how to decode and encode the backing type "' + underlyingType + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
   }, function () {
       return Error('The JSONCoding plugin does not know how to decode and encode the type "' + attribute.type.name + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
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
       return [];
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
       return [instanceToDictionaryMethod(objectType.attributes),
               dictionaryToInstanceMethod(objectType.attributes)];
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
       const unsupportedTypeErrors = objectType.attributes.filter(doesValueAttributeContainAnUnsupportedType).map(pApplyf2(objectType, valueAttributeToUnsupportedTypeError));
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