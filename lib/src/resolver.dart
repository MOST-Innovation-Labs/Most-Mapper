import 'names.dart';
import 'schema.dart';
import 'type_system.dart';

final _defaultConverters = [
  ConverterDef(
    name: null,
    from: dateTimeType,
    to: stringType,
    dart: DartCodeSpec(
      imports: [],
      expression: 'source.toUtc().toIso8601String()',
    ),
    csharp: CSharpCodeSpec(
      usings: ['System.Globalization'],
      expression:
          'source.ToUniversalTime().ToString("yyyy-MM-dd\'T\'HH:mm:ss\'Z\'", '
          'System.Globalization.CultureInfo.InvariantCulture)',
    ),
  ),
  ConverterDef(
    name: null,
    from: stringType,
    to: dateTimeType,
    dart: DartCodeSpec(
      imports: [],
      expression: 'DateTime.parse(source).toUtc()',
    ),
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

sealed class ConversionPlan {
  const ConversionPlan({required this.from, required this.to});

  final TypeRef from;
  final TypeRef to;

  Iterable<ConverterDef> get usedConverters => const [];
}

class IdentityConversionPlan extends ConversionPlan {
  const IdentityConversionPlan({required super.from, required super.to});
}

class NullableConversionPlan extends ConversionPlan {
  const NullableConversionPlan({
    required super.from,
    required super.to,
    required this.inner,
  });

  final ConversionPlan inner;

  @override
  Iterable<ConverterDef> get usedConverters => inner.usedConverters;
}

class ListConversionPlan extends ConversionPlan {
  const ListConversionPlan({
    required super.from,
    required super.to,
    required this.item,
  });

  final ConversionPlan item;

  @override
  Iterable<ConverterDef> get usedConverters => item.usedConverters;
}

class NumericConversionPlan extends ConversionPlan {
  const NumericConversionPlan({required super.from, required super.to});
}

enum EnumScalarKind { string, int }

class EnumScalarConversionPlan extends ConversionPlan {
  const EnumScalarConversionPlan({
    required super.from,
    required super.to,
    required this.enumName,
    required this.kind,
    required this.fromEnum,
  });

  final String enumName;
  final EnumScalarKind kind;
  final bool fromEnum;
}

class ModelMappingConversionPlan extends ConversionPlan {
  const ModelMappingConversionPlan({
    required super.from,
    required super.to,
    required this.mapping,
  });

  final MappingDef mapping;
}

class ConverterConversionPlan extends ConversionPlan {
  const ConverterConversionPlan({
    required super.from,
    required super.to,
    required this.converter,
  });

  final ConverterDef converter;

  @override
  Iterable<ConverterDef> get usedConverters => [converter];
}

sealed class ResolvedFieldAssignment {
  const ResolvedFieldAssignment({required this.targetField});

  final FieldDef targetField;
}

class ResolvedSourceFieldAssignment extends ResolvedFieldAssignment {
  const ResolvedSourceFieldAssignment({
    required super.targetField,
    required this.sourceField,
    required this.conversion,
  });

  final FieldDef sourceField;
  final ConversionPlan conversion;
}

class ResolvedConstantFieldAssignment extends ResolvedFieldAssignment {
  const ResolvedConstantFieldAssignment({
    required super.targetField,
    required this.constValue,
  });

  final Object? constValue;
}

class ResolvedSchema {
  ResolvedSchema(this.schema)
    : converters = [..._defaultConverters, ...schema.converters];

  final MapperSchema schema;
  final List<ConverterDef> converters;

  Iterable<DataModelDef> get dataModels =>
      schema.models.values.whereType<DataModelDef>();

  Iterable<EnumModelDef> get enumModels =>
      schema.models.values.whereType<EnumModelDef>();

  DataModelDef dataModel(String name) => schema.models[name]! as DataModelDef;

  EnumModelDef enumModel(String name) => schema.models[name]! as EnumModelDef;

  bool isDataModel(String name) => schema.models[name] is DataModelDef;

  bool isEnum(String name) => schema.models[name] is EnumModelDef;

  bool isKnownType(String name) =>
      name == 'List' ||
      isScalarTypeName(name) ||
      schema.models.containsKey(name);

  bool enumHasStrings(EnumModelDef enumDef) {
    return enumDef.values.values.every((value) => value.stringValue != null);
  }

  bool enumHasInts(EnumModelDef enumDef) {
    return enumDef.values.values.every((value) => value.intValue != null);
  }

  bool enumUsesStringJson(EnumModelDef enumDef) => enumHasStrings(enumDef);

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
      if (converter.from.sameShape(
            from.nonNullable,
            includeNullability: false,
          ) &&
          converter.to.sameShape(to.nonNullable, includeNullability: false)) {
        return converter;
      }
    }
    return null;
  }

  ConverterDef? defaultConverterFor(TypeRef from, TypeRef to) {
    for (final converter in _defaultConverters.reversed) {
      if (converter.from.sameShape(
            from.nonNullable,
            includeNullability: false,
          ) &&
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
        if (!_defaultConverters.contains(converter) ||
            usedConverters.contains(converter))
          converter,
    ];
  }

  Set<ConverterDef> usedConverters() {
    final used = <ConverterDef>{};
    for (final model in dataModels) {
      if (!model.json) {
        continue;
      }
      for (final field in model.fields.values) {
        used.addAll(jsonConvertersFor(field.type));
      }
    }
    for (final mapping in schema.mappings) {
      for (final assignment in mappingAssignments(mapping)) {
        if (assignment case ResolvedSourceFieldAssignment(:final conversion)) {
          used.addAll(conversion.usedConverters);
        }
      }
    }
    return used;
  }

  Iterable<ConverterDef> jsonConvertersFor(TypeRef type) sync* {
    if (type.nullable) {
      yield* jsonConvertersFor(type.nonNullable);
      return;
    }
    if (type.isList) {
      yield* jsonConvertersFor(type.item!);
      return;
    }
    if (type.name == dateTimeType.name) {
      final toJson = converterFor(type, stringType);
      if (toJson != null) {
        yield toJson;
      }
      final fromJson = converterFor(stringType, type);
      if (fromJson != null) {
        yield fromJson;
      }
    }
  }

  List<ResolvedFieldAssignment> mappingAssignments(MappingDef mapping) {
    final fromModel = dataModel(mapping.from);
    final toModel = dataModel(mapping.to);
    return [
      for (final targetField in toModel.fields.values)
        _mappingAssignment(fromModel, targetField, mapping),
    ];
  }

  ResolvedFieldAssignment _mappingAssignment(
    DataModelDef fromModel,
    FieldDef targetField,
    MappingDef mapping,
  ) {
    final fieldMapping = mapping.fields[targetField.name];
    if (fieldMapping == null) {
      final sourceField = fromModel.fields[targetField.name]!;
      return ResolvedSourceFieldAssignment(
        targetField: targetField,
        sourceField: sourceField,
        conversion: conversionPlanFor(sourceField.type, targetField.type)!,
      );
    }
    if (fieldMapping.hasConst) {
      return ResolvedConstantFieldAssignment(
        targetField: targetField,
        constValue: fieldMapping.constValue,
      );
    }

    final sourceField = fromModel.fields[fieldMapping.fromField]!;
    return ResolvedSourceFieldAssignment(
      targetField: targetField,
      sourceField: sourceField,
      conversion: conversionPlanFor(
        sourceField.type,
        targetField.type,
        converterName: fieldMapping.converterName,
      )!,
    );
  }

  bool canConvert(TypeRef from, TypeRef to) {
    return conversionPlanFor(from, to) != null;
  }

  bool canConvertNonNull(TypeRef from, TypeRef to) {
    return _conversionPlanForNonNull(from.nonNullable, to.nonNullable) != null;
  }

  ConversionPlan? conversionPlanFor(
    TypeRef from,
    TypeRef to, {
    String? converterName,
  }) {
    if (converterName == null && from.sameShape(to)) {
      return IdentityConversionPlan(from: from, to: to);
    }
    if (from.nullable && !to.nullable) {
      return null;
    }
    if (from.nullable && to.nullable) {
      final inner = _conversionPlanForNonNull(
        from.nonNullable,
        to.nonNullable,
        converterName: converterName,
      );
      if (inner == null) {
        return null;
      }
      return NullableConversionPlan(from: from, to: to, inner: inner);
    }
    return _conversionPlanForNonNull(
      from.nonNullable,
      to.nonNullable,
      converterName: converterName,
    );
  }

  ConversionPlan? _conversionPlanForNonNull(
    TypeRef from,
    TypeRef to, {
    final String? converterName,
  }) {
    if (converterName == 'default') {
      final converter = defaultConverterFor(from, to);
      if (converter == null) {
        return null;
      }
      return ConverterConversionPlan(from: from, to: to, converter: converter);
    }

    if (converterName != null) {
      final converter = converterByName(converterName);
      if (converter == null ||
          !converter.from.sameShape(from, includeNullability: false) ||
          !converter.to.sameShape(to, includeNullability: false)) {
        return null;
      }
      return ConverterConversionPlan(from: from, to: to, converter: converter);
    }

    if (from.sameShape(to, includeNullability: false)) {
      return IdentityConversionPlan(from: from, to: to);
    }
    if (from.isList && to.isList) {
      final item = conversionPlanFor(from.item!, to.item!);
      if (item == null) {
        return null;
      }
      return ListConversionPlan(from: from, to: to, item: item);
    }
    if (isNumericType(from) && isNumericType(to)) {
      return NumericConversionPlan(from: from, to: to);
    }
    if (isEnum(from.name) &&
        to.name == stringType.name &&
        enumHasStrings(enumModel(from.name))) {
      return EnumScalarConversionPlan(
        from: from,
        to: to,
        enumName: from.name,
        kind: EnumScalarKind.string,
        fromEnum: true,
      );
    }
    if (from.name == stringType.name &&
        isEnum(to.name) &&
        enumHasStrings(enumModel(to.name))) {
      return EnumScalarConversionPlan(
        from: from,
        to: to,
        enumName: to.name,
        kind: EnumScalarKind.string,
        fromEnum: false,
      );
    }
    if (isEnum(from.name) &&
        to.name == 'int' &&
        enumHasInts(enumModel(from.name))) {
      return EnumScalarConversionPlan(
        from: from,
        to: to,
        enumName: from.name,
        kind: EnumScalarKind.int,
        fromEnum: true,
      );
    }
    if (from.name == 'int' &&
        isEnum(to.name) &&
        enumHasInts(enumModel(to.name))) {
      return EnumScalarConversionPlan(
        from: from,
        to: to,
        enumName: to.name,
        kind: EnumScalarKind.int,
        fromEnum: false,
      );
    }
    if (isDataModel(from.name) && isDataModel(to.name)) {
      final mapping = mappingFor(from, to);
      if (mapping != null) {
        return ModelMappingConversionPlan(from: from, to: to, mapping: mapping);
      }
    }

    final converter = converterFor(from, to);
    if (converter != null) {
      return ConverterConversionPlan(from: from, to: to, converter: converter);
    }
    return null;
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
      _validateType(
        field.type,
        'models.${model.name}.fields.${field.name}',
        errors,
      );
      _recordIdentifier(
        dartNames,
        dartFieldName(field.name),
        field.name,
        'Dart',
        model.name,
        errors,
      );
      _recordIdentifier(
        csharpNames,
        csharpPropertyName(field.name),
        field.name,
        'C#',
        model.name,
        errors,
      );
      if (model.json && !_canUseJson(field.type)) {
        errors.add(
          'models.${model.name}.fields.${field.name} is not JSON serializable.',
        );
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
      _recordIdentifier(
        dartNames,
        dartEnumValueName(value.name),
        value.name,
        'Dart enum',
        model.name,
        errors,
      );
      _recordIdentifier(
        csharpNames,
        csharpEnumValueName(value.name),
        value.name,
        'C# enum',
        model.name,
        errors,
      );
      if (value.stringValue != null && !strings.add(value.stringValue!)) {
        errors.add(
          'models.${model.name}.enum has duplicate string value ${value.stringValue}.',
        );
      }
      if (value.intValue != null && !ints.add(value.intValue!)) {
        errors.add(
          'models.${model.name}.enum has duplicate int value ${value.intValue}.',
        );
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
      errors.add(
        'mappings ${mapping.from}->${mapping.to} references non-data source model ${mapping.from}.',
      );
      return;
    }
    if (to is! DataModelDef) {
      errors.add(
        'mappings ${mapping.from}->${mapping.to} references non-data target model ${mapping.to}.',
      );
      return;
    }

    for (final entry in mapping.fields.entries) {
      final targetField = to.fields[entry.key];
      if (targetField == null) {
        errors.add(
          'mappings ${mapping.from}->${mapping.to} references unknown target field ${entry.key}.',
        );
        continue;
      }
      final fieldMapping = entry.value;
      if (fieldMapping.hasConst) {
        _validateConstant(
          fieldMapping.constValue,
          targetField.type,
          entry.key,
          errors,
        );
        continue;
      }
      final sourceField = from.fields[fieldMapping.fromField];
      if (sourceField == null) {
        errors.add(
          'mappings ${mapping.from}->${mapping.to} references unknown source field ${fieldMapping.fromField}.',
        );
        continue;
      }
      if (fieldMapping.converterName case final String converterName
          when converterName != 'default') {
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
        errors.add(
          'mappings ${mapping.from}->${mapping.to} does not assign target field ${targetField.name}.',
        );
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
    if (!converter.from.sameShape(
          from.nonNullable,
          includeNullability: false,
        ) ||
        !converter.to.sameShape(to.nonNullable, includeNullability: false)) {
      errors.add(
        'mappings ${mapping.from}->${mapping.to}.$targetFieldName converter $converterName has type '
        '${converter.from.display}->${converter.to.display}, expected '
        '${from.nonNullable.display}->${to.nonNullable.display}.',
      );
    }
  }

  void _validateConstant(
    Object? value,
    TypeRef target,
    String targetName,
    List<String> errors,
  ) {
    if (value == null) {
      if (!target.nullable) {
        errors.add(
          'const null can only be assigned to nullable target field $targetName.',
        );
      }
      return;
    }

    final targetType = target.nonNullable;
    final valid = switch (value) {
      String() => targetType.name == stringType.name,
      bool() => targetType.name == 'bool',
      int() => isNumericType(targetType),
      double() =>
        targetType.name == 'double' ||
            targetType.name == 'num' ||
            targetType.name == 'decimal',
      _ => false,
    };
    if (!valid) {
      errors.add(
        'const value for $targetName is not assignable to ${target.display}.',
      );
    }
  }

  bool _canUseJson(TypeRef type) {
    if (type.nullable) {
      return _canUseJson(type.nonNullable);
    }
    if (type.isList) {
      return _canUseJson(type.item!);
    }
    if (type.name == dateTimeType.name) {
      return converterFor(type, stringType) != null &&
          converterFor(stringType, type) != null;
    }
    if (isScalarTypeName(type.name)) {
      return true;
    }
    if (isEnum(type.name)) {
      final enumDef = enumModel(type.name);
      return enumDef.values.values.every(
        (value) => value.stringValue != null || value.intValue != null,
      );
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
      errors.add(
        '$language identifier collision in $modelName: $previous and $raw both become $identifier.',
      );
    }
    seen[identifier] = raw;
  }
}
