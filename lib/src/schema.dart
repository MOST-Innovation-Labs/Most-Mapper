/// Error thrown when parsing, validation, or generation fails.
class MapperException implements Exception {
  /// Creates an exception with a user-facing [message].
  MapperException(this.message);

  /// Description of the failure.
  final String message;

  @override
  String toString() => message;
}

/// Parsed mapping schema.
class MapperSchema {
  /// Creates a schema from model, converter, and mapping definitions.
  MapperSchema({
    required this.models,
    required this.converters,
    required this.mappings,
  });

  /// Model definitions keyed by YAML model name.
  final Map<String, ModelDef> models;

  /// Converter definitions available to mappings and JSON helpers.
  final List<ConverterDef> converters;

  /// Typed mappings between source and target models.
  final List<MappingDef> mappings;
}

/// Base definition for a generated model.
sealed class ModelDef {
  /// Creates a model definition with its YAML [name] and optional documentation.
  ModelDef({required this.name, required this.doc});

  /// YAML model name.
  final String name;

  /// Optional model documentation emitted into generated code.
  final String? doc;
}

/// Data-class model definition.
class DataModelDef extends ModelDef {
  /// Creates a data model definition.
  DataModelDef({
    required super.name,
    required super.doc,
    required this.json,
    required this.fields,
  });

  /// Whether JSON helper methods should be generated.
  final bool json;

  /// Field definitions keyed by YAML field name.
  final Map<String, FieldDef> fields;
}

/// Enum model definition.
class EnumModelDef extends ModelDef {
  /// Creates an enum model definition.
  EnumModelDef({required super.name, required super.doc, required this.values});

  /// Enum values keyed by YAML value name.
  final Map<String, EnumValueDef> values;
}

/// Closed tagged-union model definition.
class UnionModelDef extends ModelDef {
  /// Creates a tagged union definition.
  UnionModelDef({
    required super.name,
    required super.doc,
    required this.json,
    required this.discriminator,
    required this.variants,
  });

  /// Whether JSON helper methods should be generated.
  final bool json;

  /// JSON field containing the variant tag.
  final String discriminator;

  /// Union variants keyed by generated type name.
  final Map<String, UnionVariantDef> variants;
}

/// One concrete variant of a tagged union.
class UnionVariantDef {
  /// Creates a union variant definition.
  UnionVariantDef({
    required this.name,
    required this.value,
    required this.fields,
  });

  /// Generated variant type name.
  final String name;

  /// Fixed discriminator wire value.
  final String value;

  /// Variant fields keyed by YAML field name.
  final Map<String, FieldDef> fields;
}

/// Single enum value definition.
class EnumValueDef {
  /// Creates an enum value definition.
  EnumValueDef({
    required this.name,
    required this.stringValue,
    required this.intValue,
  });

  /// YAML enum value name.
  final String name;

  /// Optional string wire value.
  final String? stringValue;

  /// Optional integer wire value.
  final int? intValue;
}

/// Data model field definition.
class FieldDef {
  /// Creates a field definition.
  FieldDef({required this.name, required this.type, required this.doc});

  /// YAML field name.
  final String name;

  /// Parsed field type.
  final TypeRef type;

  /// Optional field documentation emitted into generated code.
  final String? doc;
}

/// Parsed type reference used by fields, converters, and mappings.
class TypeRef {
  /// Creates a type reference.
  const TypeRef({required this.name, required this.nullable, this.item});

  /// Type name, or `List` for list types.
  final String name;

  /// Whether this type accepts `null`.
  final bool nullable;

  /// List item type when [isList] is true.
  final TypeRef? item;

  /// Whether this type is a `List<T>`.
  bool get isList => name == 'List';

  /// This type with nullable set to false.
  TypeRef get nonNullable => TypeRef(name: name, nullable: false, item: item);

  /// Returns this type with [nullable] set to [value].
  TypeRef withNullable(bool value) =>
      TypeRef(name: name, nullable: value, item: item);

  /// Human-readable Dart-like type text.
  String get display {
    final base = isList ? 'List<${item!.display}>' : name;
    return nullable ? '$base?' : base;
  }

  /// Whether this type has the same nested shape as [other].
  bool sameShape(TypeRef other, {bool includeNullability = true}) {
    if (name != other.name) {
      return false;
    }
    if (includeNullability && nullable != other.nullable) {
      return false;
    }
    if (isList) {
      return item!.sameShape(
        other.item!,
        includeNullability: includeNullability,
      );
    }
    return true;
  }

  @override
  String toString() => display;
}

/// Converter definition between two schema types.
class ConverterDef {
  /// Creates a converter definition.
  ConverterDef({
    required this.name,
    required this.from,
    required this.to,
    required this.dart,
    required this.csharp,
  });

  /// Optional converter name used by explicit mapping selectors.
  final String? name;

  /// Source type accepted by the converter.
  final TypeRef from;

  /// Target type produced by the converter.
  final TypeRef to;

  /// Dart code emitted for the converter.
  final DartCodeSpec dart;

  /// C# code emitted for the converter.
  final CSharpCodeSpec csharp;
}

/// Dart converter code specification.
class DartCodeSpec {
  /// Creates a Dart converter code specification.
  DartCodeSpec({required this.imports, required this.expression});

  /// Imports required by [expression].
  final List<String> imports;

  /// Dart expression that returns the converted value.
  final String expression;
}

/// C# converter code specification.
class CSharpCodeSpec {
  /// Creates a C# converter code specification.
  CSharpCodeSpec({required this.usings, required this.expression});

  /// Usings required by [expression].
  final List<String> usings;

  /// C# expression that returns the converted value.
  final String expression;
}

/// Mapping definition between two models.
class MappingDef {
  /// Creates a mapping definition.
  MappingDef({required this.from, required this.to, required this.fields});

  /// Source model name.
  final String from;

  /// Target model name.
  final String to;

  /// Explicit field mappings keyed by target field name.
  final Map<String, FieldMapping> fields;
}

/// Explicit mapping for one target field.
class FieldMapping {
  /// Maps a target field from [fromField].
  FieldMapping.from(this.fromField, {this.converterName})
    : hasConst = false,
      constValue = null,
      parameterType = null;

  /// Maps a target field from a constant value.
  FieldMapping.constant(this.constValue)
    : hasConst = true,
      fromField = null,
      converterName = null,
      parameterType = null;

  /// Maps a target field from a required mapping function parameter.
  FieldMapping.parameter(this.parameterType, {this.converterName})
    : hasConst = false,
      fromField = null,
      constValue = null;

  /// Source field name when this is a field mapping.
  final String? fromField;

  /// Parameter type when this is a parameter mapping.
  final TypeRef? parameterType;

  /// Optional converter name to force for this mapping.
  final String? converterName;

  /// Whether this mapping uses [constValue].
  final bool hasConst;

  /// Constant value assigned to the target field.
  final Object? constValue;
}
