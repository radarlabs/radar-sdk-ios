"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function matchType(matchers, type) {
    return matchTypeName(matchers, type.name);
}
exports.matchType = matchType;
/** Like matchType but allows you to pass a type name instead of an ObjC.Type. */
function matchTypeName(matchers, typeName) {
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
    else if (typeName === 'CGFloat') {
        return matchers.CGFloat();
    }
    else if (typeName === 'NSTimeInterval') {
        return matchers.NSTimeInterval();
    }
    else if (typeName === 'uintptr_t') {
        return matchers.uintptr_t();
    }
    else if (typeName === 'uint32_t') {
        return matchers.uint32_t();
    }
    else if (typeName === 'uint64_t') {
        return matchers.uint64_t();
    }
    else if (typeName === 'int32_t') {
        return matchers.int32_t();
    }
    else if (typeName === 'int64_t') {
        return matchers.int64_t();
    }
    else if (typeName === 'SEL') {
        return matchers.SEL();
    }
    else if (typeName === 'NSRange') {
        return matchers.NSRange();
    }
    else if (typeName === 'CGRect') {
        return matchers.CGRect();
    }
    else if (typeName === 'CGPoint') {
        return matchers.CGPoint();
    }
    else if (typeName === 'CGSize') {
        return matchers.CGSize();
    }
    else if (typeName === 'UIEdgeInsets') {
        return matchers.UIEdgeInsets();
    }
    else if (typeName === 'Class') {
        return matchers.Class();
    }
    else if (typeName === 'dispatch_block_t') {
        return matchers.dispatch_block_t();
    }
    else {
        return matchers.unmatchedType();
    }
}
exports.matchTypeName = matchTypeName;
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
function stringContainingSpaces(spaces) {
    var str = '';
    for (var i = 0; i < spaces; i++) {
        str += ' ';
    }
    return str;
}
function indentFunc(spaces, str) {
    if (str !== '') {
        return stringContainingSpaces(spaces) + str;
    }
    else {
        return str;
    }
}
function strIndent(spaces) {
    return str => indentFunc(spaces, str);
}
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
function pApplyf2(val, f) {
    return function (b) {
        return f(val, b);
    };
}
const noChange = (attributeName) => attributeName;
function dictionaryWrappingAmpersand(attributeName) {
    return "@(" + attributeName + ")";
}
function dictionaryUnwrappingByKeyword(unwrappingKeyword) {
    return function (attributeName) {
        return "[" + attributeName + " " + unwrappingKeyword + "]";
    };
}
function dictionaryParsingFunction(attribute) {
    const iVarString = '_' + attribute.name;
    const type = computeTypeOfAttribute(attribute);
    const defaultParsingFunction = {
        keyFromModelGenerator: noChange,
        keyToModelGenerator: noChange,
    };
    return matchType({
        id: function () {
            return defaultParsingFunction;
        },
        NSObject: function () {
            const typeName = attribute.type.name;
            const keyToModelGenerator = (val) => {
                if (typeName === 'RadarCoordinate') {
                    return `[dictionary radar_coordinateForKey:@"${attribute.name}"]`;
                }
                else if (typeName.startsWith('Radar')) {
                    return `[[${typeName} alloc] initWithRadarJSONObject:${val}]`;
                }
                else if (typeName === 'NSArray') {
                    return `[NSArray fromRadarJSONObject:${val}]`;
                }
                else {
                    return `(${typeName} *)${val}`;
                }
            };
            const keyFromModelGenerator = (val) => {
                if (typeName.startsWith('Radar')) {
                    return `[_${attribute.name} dictionaryValue]`;
                }
                else if (typeName === 'NSArray') {
                    return `[_${attribute.name} toRadarJSONObject]`;
                }
                else {
                    return val;
                }
            };
            return {
                keyFromModelGenerator,
                keyToModelGenerator,
            };
        },
        BOOL: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("boolValue"),
            };
        },
        NSInteger: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("integerValue"),
            };
        },
        NSUInteger: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("unsignedIntegerValue"),
            };
        },
        double: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("doubleValue"),
            };
        },
        float: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("floatValue"),
            };
        },
        CGFloat: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("floatValue"),
            };
        },
        NSTimeInterval: function () {
            return {
                keyFromModelGenerator: dictionaryWrappingAmpersand,
                keyToModelGenerator: dictionaryUnwrappingByKeyword("doubleValue"),
            };
        },
        uintptr_t: function () {
            return null;
        },
        uint32_t: function () {
            return null;
        },
        uint64_t: function () {
            return null;
        },
        int32_t: function () {
            return null;
        },
        int64_t: function () {
            return null;
        },
        SEL: function () {
            return null;
        },
        NSRange: function () {
            return null;
        },
        CGRect: function () {
            return null;
        },
        CGPoint: function () {
            return null;
        },
        CGSize: function () {
            return null;
        },
        UIEdgeInsets: function () {
            return null;
        },
        Class: function () {
            return null;
        },
        dispatch_block_t: function () {
            return null;
        },
        unmatchedType: function () {
            return null;
        }
    }, type);
}
function toIvarKeyValuePair(attribute) {
    const iVar = '_' + attribute.name;
    const parsingFunction = dictionaryParsingFunction(attribute);
    let wrapped = iVar;
    if (parsingFunction) {
        wrapped = parsingFunction.keyFromModelGenerator(iVar);
    }
    const keyName = attribute.name;
    return attribute.nullability.match(() => {
        return 'dict[@"' + keyName + '"] = ' + wrapped + ';';
    }, () => {
        return 'dict[@"' + keyName + '"] = ' + wrapped + ';';
    }, // nonnull
    () => {
        return [
            `if (${iVar}) {`,
            strIndent(2)('dict[@"' + keyName + '"] = ' + wrapped + ';'),
            '}'
        ].join('\n');
    });
}
function instanceToDictionaryConverter(attributes) {
    const result = [
        'NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];'
    ].concat(attributes.map(toIvarKeyValuePair))
        .concat([
        'return [dict copy];',
    ]);
    return result;
}
function instanceToDictionaryMethod(attributes) {
    return {
        preprocessors: [],
        belongsToProtocol: null,
        code: instanceToDictionaryConverter(attributes),
        comments: [],
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
function safeUnwrapDecodingStatement(parsingFunction, decodingStatement) {
    let unwrapped = decodingStatement;
    if (parsingFunction) {
        unwrapped = parsingFunction.keyToModelGenerator(unwrapped);
    }
    return unwrapped;
}
function toIvarAssignment(supportsValueSemantics, attribute) {
    const keyName = attribute.name;
    const raw = 'dictionary[@"' + keyName + '"]';
    const parsingFunction = dictionaryParsingFunction(attribute);
    const unwrapped = safeUnwrapDecodingStatement(parsingFunction, raw);
    let decoded = unwrapped;
    //    const shouldCopy = ObjectSpecCodeUtils.shouldCopyIncomingValueForAttribute(supportsValueSemantics, attribute);
    decoded = decoded + ";";
    let res;
    return attribute.nullability.match(() => {
        return [
            `if (!${raw}) {`,
            strIndent(4)('return nil;'),
            '}',
            '_' + attribute.name + ' = ' + decoded
        ].join('\n');
    }, () => {
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
function dictionaryToInstanceInitializer(attributes) {
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
function dictionaryToInstanceMethod(attributes) {
    return {
        preprocessors: [],
        belongsToProtocol: null,
        code: dictionaryToInstanceInitializer(attributes),
        comments: [{
                content: '// Initialization Method from Networking.'
            },
        ],
        compilerAttributes: [],
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
function doesValueAttributeContainAnUnsupportedType(attribute) {
    return dictionaryParsingFunction(attribute) == null;
}
function valueAttributeToUnsupportedTypeError(objectType, attribute) {
    return match(function (underlyingType) {
        return Error('The JSONCoding plugin does not know how to decode and encode the backing type "' + underlyingType + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
    }, function () {
        return Error('The JSONCoding plugin does not know how to decode and encode the type "' + attribute.type.name + '" from ' + objectType.typeName + '.' + attribute.name + '. ' + attribute.type.name + ' is not supported.');
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
            return [];
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
            return [instanceToDictionaryMethod(objectType.attributes),
                dictionaryToInstanceMethod(objectType.attributes)];
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
            const unsupportedTypeErrors = objectType.attributes.filter(doesValueAttributeContainAnUnsupportedType).map(pApplyf2(objectType, valueAttributeToUnsupportedTypeError));
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
