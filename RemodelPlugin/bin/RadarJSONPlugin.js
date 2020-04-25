"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function matchType(matchers, type) {
    const typeName = type.name;
    if (typeName === 'id') {
        return matchers.id();
    }
    else if (typeName === 'NSObject') {
        return matchers.NSObject();
    }
    else if (typeName === 'BOOL') {
        return matchers.BOOL();
    }
    else if (typeName === 'NSInteger') {
        return matchers.NSInteger();
    }
    else if (typeName === 'NSUInteger') {
        return matchers.NSUInteger();
    }
    else if (typeName === 'double') {
        return matchers.double();
    }
    else if (typeName === 'float') {
        return matchers.float();
    }
    else {
        return matchers.unmatchedType();
    }
    // return matchTypeName(matchers, type.name);
}
exports.matchType = matchType;
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
var ClassNullability;
(function (ClassNullability) {
    ClassNullability[ClassNullability["default"] = 0] = "default";
    ClassNullability[ClassNullability["assumeNonnull"] = 1] = "assumeNonnull";
})(ClassNullability || (ClassNullability = {}));
function Error(reason) {
    return { reason: reason };
}
var FileType;
(function (FileType) {
    FileType[FileType["ObjectiveC"] = 0] = "ObjectiveC";
    FileType[FileType["ObjectiveCPlusPlus"] = 1] = "ObjectiveCPlusPlus";
})(FileType || (FileType = {}));
var KeywordArgumentModifierType;
(function (KeywordArgumentModifierType) {
    KeywordArgumentModifierType[KeywordArgumentModifierType["nonnull"] = 0] = "nonnull";
    KeywordArgumentModifierType[KeywordArgumentModifierType["nullable"] = 1] = "nullable";
    KeywordArgumentModifierType[KeywordArgumentModifierType["noescape"] = 2] = "noescape";
    KeywordArgumentModifierType[KeywordArgumentModifierType["unsafe_unretained"] = 3] = "unsafe_unretained";
})(KeywordArgumentModifierType || (KeywordArgumentModifierType = {}));
class KeywordArgumentModifier {
    constructor(type) {
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
        return new KeywordArgumentModifier(KeywordArgumentModifierType.unsafe_unretained);
    }
    match(nonnull, nullable, noescape, unsafe_unretained) {
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
var NullabilityType;
(function (NullabilityType) {
    NullabilityType[NullabilityType["inherited"] = 0] = "inherited";
    NullabilityType[NullabilityType["nonnull"] = 1] = "nonnull";
    NullabilityType[NullabilityType["nullable"] = 2] = "nullable";
})(NullabilityType || (NullabilityType = {}));
class Nullability {
    constructor(type) {
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
    match(inherited, nonnull, nullable) {
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
// functions
function typeForUnderlyingType(underlyingType) {
    return {
        name: underlyingType,
        reference: underlyingType === 'NSObject' ? 'NSObject*' : underlyingType,
    };
}
function match(just, nothing, maybe) {
    if (maybe == null) {
        return nothing();
    }
    else {
        return just(maybe);
    }
}
function computeTypeOfAttribute(attribute) {
    return match(typeForUnderlyingType, function () {
        return {
            name: attribute.type.name,
            reference: attribute.type.reference,
        };
    }, attribute.type.underlyingType);
}
function dictionaryWrappingAmpersand(attributeName) {
    return "@(" + attributeName + ")";
}
const isRadarClass = (name) => (name.indexOf('Radar') !== -1);
function referencedGenericTypesIncludesRadarClass(genericType) {
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
function isAttributeTypeUnsupported(attribute) {
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
                    }
                    else if (referencedGenericTypesIncludesRadarClass(genericType)) {
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
function toDictAssignment(attribute) {
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
        NSObject: () => {
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
            }
            else if (typeName === 'NSDictionary') {
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
            }
            else if (isRadarClass(typeName)) {
                return [`${raw} = [${ivar} dictionaryValue];`];
            }
            else {
                return defaultAssignment;
            }
        },
        unmatchedType: () => []
    }, type);
    const withNullability = attribute.nullability.match(() => assignment, () => assignment, () => {
        return [
            `if (${ivar}) {`
        ].concat(assignment)
            .concat([
            '}',
        ]);
    });
    return withNullability.join(`\n`);
}
function instanceToJSONConverter(attributes) {
    const result = [
        'NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];'
    ].concat(attributes.map(toDictAssignment))
        .concat([
        'return [dictionary copy];',
    ]);
    return result;
}
function instanceToJSONMethod(attributes) {
    return {
        preprocessors: [],
        belongsToProtocol: 'RadarJSONCoding',
        code: instanceToJSONConverter(attributes),
        comments: [{
                content: '// Convert to JSON object (either an dictionary or array).'
            },
        ],
        compilerAttributes: [],
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
function toIvarAssignment(attribute) {
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
            const defaultAssignmentLine = `${ivar} = (${typeName} *)${raw};`;
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
            }
            else if (typeName === 'NSDictionary') {
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
            }
            else if (typeName === 'NSNumber' || typeName === 'NSString') {
                return [
                    `if (${raw} && [${raw} isKindOfClass:[${typeName} class]]) {`,
                    defaultAssignmentLine,
                    `}`,
                ];
            }
            else if (isRadarClass(typeName)) {
                return [
                    `if (${raw} && [${raw} isKindOfClass:[NSDictionary class]]) {`,
                    `${ivar} = [[${typeName} alloc] initWithObject:${raw}];`,
                    `}`,
                ];
            }
            else {
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
        return assignment.join('\n');
    }
    const nullabilityCheck = attribute.nullability.match(() => {
        // this is assumeNonnull
        return [
            `if (!${ivar}) {`,
            `self = nil;`,
            `return self;`,
            '}',
        ];
    }, () => {
        return [
            `if (!${ivar}) {`,
            `self = nil;`,
            `return self;`,
            '}',
        ];
    }, () => {
        return null;
    });
    if (nullabilityCheck) {
        return assignment.concat(nullabilityCheck).join('\n');
    }
    else {
        return assignment.join('\n');
    }
}
function JSONToInstanceInitializer(objectType) {
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
function JSONToInstanceMethod(objectType) {
    return {
        preprocessors: [],
        belongsToProtocol: 'RadarJSONCoding',
        code: JSONToInstanceInitializer(objectType),
        comments: [{
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
function JSONArrayToInstanceCode(objectType) {
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
function JSONArrayToInstanceMethod(objectType) {
    return {
        preprocessors: [],
        belongsToProtocol: 'RadarJSONCoding',
        code: JSONArrayToInstanceCode(objectType),
        comments: [],
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
function createPlugin() {
    return {
        additionalFiles: function (objectType) {
            return [];
        },
        transformBaseFile: function (objectType, baseFile) {
            return baseFile;
        },
        additionalTypes: function (objectType) {
            return [];
        },
        attributes: function (objectType) {
            return [];
        },
        classMethods: function (objectType) {
            return [JSONArrayToInstanceMethod(objectType)];
        },
        transformFileRequest: function (request) {
            return request;
        },
        fileType: function (objectType) {
            return null;
        },
        forwardDeclarations: function (objectType) {
            return [];
        },
        functions: function (objectType) {
            return [];
        },
        headerComments: function (objectType) {
            return [];
        },
        imports: function (objectType) {
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
        implementedProtocols: function (objectType) {
            return [
                {
                    name: 'RadarJSONCoding',
                },
            ];
        },
        instanceMethods: function (objectType) {
            return [instanceToJSONMethod(objectType.attributes),
                JSONToInstanceMethod(objectType)];
        },
        macros: function (valueType) {
            return [];
        },
        properties: function (objectType) {
            return [];
        },
        requiredIncludesToRun: ['RadarJSONCoding'],
        staticConstants: function (objectType) {
            return [];
        },
        validationErrors: function (objectType) {
            const unsupportedTypeErrors = [];
            const unsupportedAttributes = objectType.attributes.filter(isAttributeTypeUnsupported);
            for (const attribute of unsupportedAttributes) {
                const error = valueAttributeToUnsupportedTypeError(objectType, attribute);
                unsupportedTypeErrors.push(error);
            }
            return unsupportedTypeErrors;
        },
        nullability: function (objectType) {
            return null;
        },
        subclassingRestricted: function (objectType) {
            return false;
        },
    };
}
exports.createPlugin = createPlugin;
