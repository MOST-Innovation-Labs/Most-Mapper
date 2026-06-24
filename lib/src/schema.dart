class MapperException implements Exception {
  MapperException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MapperSchema {
  MapperSchema({required this.models, required this.converters, required this.mappings});

  final Map<String, ModelDef> models;
  final List<ConverterDef> converters;
  final List<MappingDef> mappings;
}

sealed class ModelDef {
  ModelDef({required this.name, required this.doc});

  final String name;
  final String? doc;
}

class DataModelDef extends ModelDef {
  DataModelDef({required super.name, required super.doc, required this.json, required this.fields});

  final bool json;
  final Map<String, FieldDef> fields;
}

class EnumModelDef extends ModelDef {
  EnumModelDef({required super.name, required super.doc, required this.values});

  final Map<String, EnumValueDef> values;
}

class EnumValueDef {
  EnumValueDef({required this.name, required this.stringValue, required this.intValue});

  final String name;
  final String? stringValue;
  final int? intValue;
}

class FieldDef {
  FieldDef({required this.name, required this.type, required this.doc});

  final String name;
  final TypeRef type;
  final String? doc;
}

class TypeRef {
  const TypeRef({required this.name, required this.nullable, this.item});

  final String name;
  final bool nullable;
  final TypeRef? item;

  bool get isList => name == 'List';

  TypeRef get nonNullable => TypeRef(name: name, nullable: false, item: item);

  TypeRef withNullable(bool value) => TypeRef(name: name, nullable: value, item: item);

  String get display {
    final base = isList ? 'List<${item!.display}>' : name;
    return nullable ? '$base?' : base;
  }

  bool sameShape(TypeRef other, {bool includeNullability = true}) {
    if (name != other.name) {
      return false;
    }
    if (includeNullability && nullable != other.nullable) {
      return false;
    }
    if (isList) {
      return item!.sameShape(other.item!, includeNullability: includeNullability);
    }
    return true;
  }

  @override
  String toString() => display;
}

class ConverterDef {
  ConverterDef({required this.name, required this.from, required this.to, required this.dart, required this.csharp});

  final String? name;
  final TypeRef from;
  final TypeRef to;
  final DartCodeSpec dart;
  final CSharpCodeSpec csharp;
}

class DartCodeSpec {
  DartCodeSpec({required this.imports, required this.expression});

  final List<String> imports;
  final String expression;
}

class CSharpCodeSpec {
  CSharpCodeSpec({required this.usings, required this.expression});

  final List<String> usings;
  final String expression;
}

class MappingDef {
  MappingDef({required this.from, required this.to, required this.fields});

  final String from;
  final String to;
  final Map<String, FieldMapping> fields;
}

class FieldMapping {
  FieldMapping.from(this.fromField, {this.converterName}) : hasConst = false, constValue = null;

  FieldMapping.constant(this.constValue) : hasConst = true, fromField = null, converterName = null;

  final String? fromField;
  final String? converterName;
  final bool hasConst;
  final Object? constValue;
}
