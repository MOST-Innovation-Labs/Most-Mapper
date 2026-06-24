import 'names.dart';
import 'schema.dart';

const _scalarTypes = {'String', 'bool', 'int', 'double', 'num', 'decimal', 'DateTime'};
const _numericTypes = {'int', 'double', 'num', 'decimal'};
const _stringType = TypeRef(name: 'String', nullable: false);
const _dateTimeType = TypeRef(name: 'DateTime', nullable: false);

final _defaultConverters = [
  ConverterDef(
    name: null,
    from: _dateTimeType,
    to: _stringType,
    dart: DartCodeSpec(imports: [], expression: 'source.toUtc().toIso8601String()'),
    csharp: CSharpCodeSpec(
      usings: ['System.Globalization'],
      expression:
          'source.ToUniversalTime().ToString("yyyy-MM-dd\'T\'HH:mm:ss\'Z\'", '
          'System.Globalization.CultureInfo.InvariantCulture)',
    ),
  ),
  ConverterDef(
    name: null,
    from: _stringType,
    to: _dateTimeType,
    dart: DartCodeSpec(imports: [], expression: 'DateTime.parse(source).toUtc()'),
    csharp: CSharpCodeSpec(
      usings: ['System.Globalization'],
      expression:
          'System.DateTime.ParseExact(source, "yyyy-MM-dd\'T\'HH:mm:ss\'Z\'", '
          'System.Globalization.CultureInfo.InvariantCulture, '
          'System.Globalization.DateTimeStyles.AssumeUniversal | '
          'System.Globalization.DateTimeStyles.AdjustToUniversal)',
    ),
  ),
];

class ResolvedSchema {
  ResolvedSchema(this.schema) : converters = [..._defaultConverters, ...schema.converters];

  final MapperSchema schema;
  final List<ConverterDef> converters;

  Iterable<DataModelDef> get dataModels => schema.models.values.whereType<DataModelDef>();

  Iterable<EnumModelDef> get enumModels => schema.models.values.whereType<EnumModelDef>();

  DataModelDef dataModel(String name) => schema.models[name]! as DataModelDef;

  EnumModelDef enumModel(String name) => schema.models[name]! as EnumModelDef;

  bool isDataModel(String name) => schema.models[name] is DataModelDef;

  bool isEnum(String name) => schema.models[name] is EnumModelDef;

  bool isKnownType(String name) => name == 'List' || _scalarTypes.contains(name) || schema.models.containsKey(name);

  MappingDef? mappingFor(TypeRef from, TypeRef to) {
    for (final mapping in schema.mappings) {
      if (mapping.from == from.name && mapping.to == to.name) {
        return mapping;
      }
    }
    return null;
  }

  ConverterDef? converterFor(TypeRef from, TypeRef to) {
    for (final converter in converters.reversed) {
      if (converter.from.sameShape(from.nonNullable, includeNullability: false) &&
          converter.to.sameShape(to.nonNullable, includeNullability: false)) {
        return converter;
      }
    }
    return null;
  }

  ConverterDef? defaultConverterFor(TypeRef from, TypeRef to) {
    for (final converter in _defaultConverters.reversed) {
      if (converter.from.sameShape(from.nonNullable, includeNullability: false) &&
          converter.to.sameShape(to.nonNullable, includeNullability: false)) {
        return converter;
      }
    }
    return null;
  }

  ConverterDef? converterByName(String name) {
    for (final converter in converters.reversed) {
      if (converter.name == name) {
        return converter;
      }
    }
    return null;
  }

  List<ConverterDef> convertersToEmit(Set<ConverterDef> usedConverters) {
    return [
      for (final converter in converters)
        if (!_defaultConverters.contains(converter) || usedConverters.contains(converter)) converter,
    ];
  }

  bool canConvert(TypeRef from, TypeRef to) {
    if (from.nullable && !to.nullable) {
      return false;
    }
    return canConvertNonNull(from.nonNullable, to.nonNullable);
  }

  bool canConvertNonNull(TypeRef from, TypeRef to) {
    if (from.sameShape(to, includeNullability: false)) {
      return true;
    }
    if (from.isList && to.isList) {
      return canConvert(from.item!, to.item!);
    }
    if (_numericTypes.contains(from.name) && _numericTypes.contains(to.name)) {
      return true;
    }
    if (isEnum(from.name) && to.name == 'String') {
      return enumModel(from.name).values.values.every((value) => value.stringValue != null);
    }
    if (from.name == 'String' && isEnum(to.name)) {
      return enumModel(to.name).values.values.every((value) => value.stringValue != null);
    }
    if (isEnum(from.name) && to.name == 'int') {
      return enumModel(from.name).values.values.every((value) => value.intValue != null);
    }
    if (from.name == 'int' && isEnum(to.name)) {
      return enumModel(to.name).values.values.every((value) => value.intValue != null);
    }
    if (isDataModel(from.name) && isDataModel(to.name) && mappingFor(from, to) != null) {
      return true;
    }
    return converterFor(from, to) != null;
  }

  void validate() {
    final errors = <String>[];
    for (final model in schema.models.values) {
      if (model is DataModelDef) {
        _validateDataModel(model, errors);
      } else if (model is EnumModelDef) {
        _validateEnum(model, errors);
      }
    }
    for (final converter in converters) {
      _validateType(converter.from, 'converter from type', errors);
      _validateType(converter.to, 'converter to type', errors);
    }
    _validateConverterNames(errors);
    for (final mapping in schema.mappings) {
      _validateMapping(mapping, errors);
    }

    if (errors.isNotEmpty) {
      throw MapperException(errors.join('\n'));
    }
  }

  void _validateDataModel(DataModelDef model, List<String> errors) {
    final dartNames = <String, String>{};
    final csharpNames = <String, String>{};
    for (final field in model.fields.values) {
      _validateType(field.type, 'models.${model.name}.fields.${field.name}', errors);
      _recordIdentifier(dartNames, dartFieldName(field.name), field.name, 'Dart', model.name, errors);
      _recordIdentifier(csharpNames, csharpPropertyName(field.name), field.name, 'C#', model.name, errors);
      if (model.json && !_canUseJson(field.type)) {
        errors.add('models.${model.name}.fields.${field.name} is not JSON serializable.');
      }
    }
  }

  void _validateEnum(EnumModelDef model, List<String> errors) {
    if (model.values.isEmpty) {
      errors.add('models.${model.name}.enum must contain at least one value.');
    }

    final dartNames = <String, String>{};
    final csharpNames = <String, String>{};
    final strings = <String>{};
    final ints = <int>{};
    for (final value in model.values.values) {
      _recordIdentifier(dartNames, dartEnumValueName(value.name), value.name, 'Dart enum', model.name, errors);
      _recordIdentifier(csharpNames, csharpEnumValueName(value.name), value.name, 'C# enum', model.name, errors);
      if (value.stringValue != null && !strings.add(value.stringValue!)) {
        errors.add('models.${model.name}.enum has duplicate string value ${value.stringValue}.');
      }
      if (value.intValue != null && !ints.add(value.intValue!)) {
        errors.add('models.${model.name}.enum has duplicate int value ${value.intValue}.');
      }
    }
  }

  void _validateType(TypeRef type, String context, List<String> errors) {
    if (!isKnownType(type.name)) {
      errors.add('$context references unknown type ${type.name}.');
    }
    if (type.isList) {
      _validateType(type.item!, '$context list item', errors);
    }
  }

  void _validateConverterNames(List<String> errors) {
    final seen = <String>{};
    for (final converter in converters) {
      final converterName = converter.name;
      if (converterName == 'default') {
        errors.add('default is a reserved converter name.');
      }
      if (converterName != null && !seen.add(converterName)) {
        errors.add('Duplicate converter name $converterName.');
      }
    }
  }

  void _validateMapping(MappingDef mapping, List<String> errors) {
    final from = schema.models[mapping.from];
    final to = schema.models[mapping.to];
    if (from is! DataModelDef) {
      errors.add('mappings ${mapping.from}->${mapping.to} references non-data source model ${mapping.from}.');
      return;
    }
    if (to is! DataModelDef) {
      errors.add('mappings ${mapping.from}->${mapping.to} references non-data target model ${mapping.to}.');
      return;
    }

    for (final entry in mapping.fields.entries) {
      final targetField = to.fields[entry.key];
      if (targetField == null) {
        errors.add('mappings ${mapping.from}->${mapping.to} references unknown target field ${entry.key}.');
        continue;
      }
      final fieldMapping = entry.value;
      if (fieldMapping.hasConst) {
        _validateConstant(fieldMapping.constValue, targetField.type, entry.key, errors);
        continue;
      }
      final sourceField = from.fields[fieldMapping.fromField];
      if (sourceField == null) {
        errors.add(
          'mappings ${mapping.from}->${mapping.to} references unknown source field ${fieldMapping.fromField}.',
        );
        continue;
      }
      if (fieldMapping.converterName case final String converterName when converterName != 'default') {
        _validateExplicitConverter(
          converterName,
          sourceField.type,
          targetField.type,
          mapping,
          targetField.name,
          errors,
        );
        continue;
      }
      if (!canConvert(sourceField.type, targetField.type)) {
        errors.add(
          'Cannot map ${mapping.from}.${sourceField.name} (${sourceField.type}) to '
          '${mapping.to}.${targetField.name} (${targetField.type}).',
        );
      }
    }

    for (final targetField in to.fields.values) {
      if (mapping.fields.containsKey(targetField.name)) {
        continue;
      }
      final sourceField = from.fields[targetField.name];
      if (sourceField == null) {
        errors.add('mappings ${mapping.from}->${mapping.to} does not assign target field ${targetField.name}.');
        continue;
      }
      if (!canConvert(sourceField.type, targetField.type)) {
        errors.add(
          'Cannot default-map ${mapping.from}.${sourceField.name} (${sourceField.type}) to '
          '${mapping.to}.${targetField.name} (${targetField.type}).',
        );
      }
    }
  }

  void _validateExplicitConverter(
    String converterName,
    TypeRef from,
    TypeRef to,
    MappingDef mapping,
    String targetFieldName,
    List<String> errors,
  ) {
    final converter = converterByName(converterName);
    if (converter == null) {
      errors.add(
        'mappings ${mapping.from}->${mapping.to}.$targetFieldName references unknown converter $converterName.',
      );
      return;
    }
    if (from.nullable && !to.nullable) {
      errors.add(
        'mappings ${mapping.from}->${mapping.to}.$targetFieldName uses converter $converterName for unsafe '
        'nullable source ${from.display} to non-nullable target ${to.display}.',
      );
      return;
    }
    if (!converter.from.sameShape(from.nonNullable, includeNullability: false) ||
        !converter.to.sameShape(to.nonNullable, includeNullability: false)) {
      errors.add(
        'mappings ${mapping.from}->${mapping.to}.$targetFieldName converter $converterName has type '
        '${converter.from.display}->${converter.to.display}, expected '
        '${from.nonNullable.display}->${to.nonNullable.display}.',
      );
    }
  }

  void _validateConstant(Object? value, TypeRef target, String targetName, List<String> errors) {
    if (value == null) {
      if (!target.nullable) {
        errors.add('const null can only be assigned to nullable target field $targetName.');
      }
      return;
    }

    final targetType = target.nonNullable;
    final valid = switch (value) {
      String() => targetType.name == 'String',
      bool() => targetType.name == 'bool',
      int() => _numericTypes.contains(targetType.name),
      double() => targetType.name == 'double' || targetType.name == 'num' || targetType.name == 'decimal',
      _ => false,
    };
    if (!valid) {
      errors.add('const value for $targetName is not assignable to ${target.display}.');
    }
  }

  bool _canUseJson(TypeRef type) {
    if (type.nullable) {
      return _canUseJson(type.nonNullable);
    }
    if (type.isList) {
      return _canUseJson(type.item!);
    }
    if (type.name == 'DateTime') {
      return converterFor(type, _stringType) != null && converterFor(_stringType, type) != null;
    }
    if (_scalarTypes.contains(type.name)) {
      return true;
    }
    if (isEnum(type.name)) {
      final enumDef = enumModel(type.name);
      return enumDef.values.values.every((value) => value.stringValue != null || value.intValue != null);
    }
    if (schema.models[type.name] case final DataModelDef model) {
      return model.json;
    }
    return false;
  }

  void _recordIdentifier(
    Map<String, String> seen,
    String identifier,
    String raw,
    String language,
    String modelName,
    List<String> errors,
  ) {
    final previous = seen[identifier];
    if (previous != null) {
      errors.add('$language identifier collision in $modelName: $previous and $raw both become $identifier.');
    }
    seen[identifier] = raw;
  }
}
