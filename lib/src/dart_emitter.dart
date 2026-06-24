import 'names.dart';
import 'resolver.dart';
import 'schema.dart';
import 'text_helpers.dart';

String emitDart(ResolvedSchema resolved) {
  final emitter = _DartEmitter(resolved);
  return emitter.emit();
}

class _DartEmitter {
  _DartEmitter(this.resolved);

  final ResolvedSchema resolved;
  final _usedConverters = <ConverterDef>{};
  var _converterMethodNames = <ConverterDef, String>{};

  String emit() {
    _usedConverters.clear();
    _converterMethodNames = {};
    _buildBody();

    final converters = resolved.convertersToEmit(_usedConverters);
    _converterMethodNames = dartConverterMethodNames(converters);
    _usedConverters.clear();
    final body = _buildBody();

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
    buffer.writeln('// ignore_for_file: unnecessary_parenthesis, unused_element, avoid-high-cyclomatic-complexity');
    buffer.writeln();

    final imports = <String>{};
    for (final converter in converters) {
      imports.addAll(converter.dart.imports);
    }
    for (final import in imports.toList()..sort()) {
      buffer.writeln("import '$import';");
    }
    if (imports.isNotEmpty) {
      buffer.writeln();
    }

    _writeConverters(buffer, converters);
    buffer.write(body);

    return buffer.toString();
  }

  StringBuffer _buildBody() {
    final body = StringBuffer();
    for (final enumDef in resolved.enumModels) {
      _writeEnum(body, enumDef);
    }
    for (final model in resolved.dataModels) {
      _writeDataModel(body, model);
    }
    for (final mapping in resolved.schema.mappings) {
      _writeMapping(body, mapping);
    }
    return body;
  }

  void _writeConverters(StringBuffer buffer, List<ConverterDef> converters) {
    if (converters.isEmpty) {
      return;
    }
    buffer.writeln('class MostMapperConverters {');
    buffer.writeln('  const MostMapperConverters._();');
    buffer.writeln();
    for (final converter in converters) {
      final methodName = _converterMethodNames[converter] ?? dartConverterBaseMethodName(converter);
      buffer.writeln('  static ${_dartType(converter.to)} $methodName(${_dartType(converter.from)} source) {');
      buffer.writeln('    return (${converter.dart.expression.trim()});');
      buffer.writeln('  }');
      buffer.writeln();
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeEnum(StringBuffer buffer, EnumModelDef enumDef) {
    _writeDoc(buffer, enumDef.doc);
    buffer.writeln('enum ${dartTypeName(enumDef.name)} {');
    for (final value in enumDef.values.values) {
      buffer.writeln('  ${dartEnumValueName(value.name)},');
    }
    buffer.writeln('}');
    buffer.writeln();

    if (_enumHasStrings(enumDef)) {
      buffer.writeln('String ${_enumToStringName(enumDef.name)}(${dartTypeName(enumDef.name)} value) {');
      buffer.writeln('  switch (value) {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '    case ${dartTypeName(enumDef.name)}.${dartEnumValueName(value.name)}: '
          'return ${dartStringLiteral(value.stringValue!)};',
        );
      }
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln();

      buffer.writeln('${dartTypeName(enumDef.name)} ${_enumFromStringName(enumDef.name)}(String value) {');
      buffer.writeln('  switch (value) {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '    case ${dartStringLiteral(value.stringValue!)}: '
          'return ${dartTypeName(enumDef.name)}.${dartEnumValueName(value.name)};',
        );
      }
      buffer.writeln('    default:');
      buffer.writeln(
        "      throw ArgumentError.value(value, 'value', 'Unknown ${dartTypeName(enumDef.name)} string');",
      );
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln();
    }

    if (_enumHasInts(enumDef)) {
      buffer.writeln('int ${_enumToIntName(enumDef.name)}(${dartTypeName(enumDef.name)} value) {');
      buffer.writeln('  switch (value) {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '    case ${dartTypeName(enumDef.name)}.${dartEnumValueName(value.name)}: return ${value.intValue};',
        );
      }
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln();

      buffer.writeln('${dartTypeName(enumDef.name)} ${_enumFromIntName(enumDef.name)}(int value) {');
      buffer.writeln('  switch (value) {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '    case ${value.intValue}: return ${dartTypeName(enumDef.name)}.${dartEnumValueName(value.name)};',
        );
      }
      buffer.writeln('    default:');
      buffer.writeln("      throw ArgumentError.value(value, 'value', 'Unknown ${dartTypeName(enumDef.name)} int');");
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln();
    }
  }

  void _writeDataModel(StringBuffer buffer, DataModelDef model) {
    _writeDoc(buffer, model.doc);
    buffer.writeln('class ${dartTypeName(model.name)} {');
    if (model.fields.isEmpty) {
      buffer.writeln('  const ${dartTypeName(model.name)}();');
    } else {
      buffer.writeln('  const ${dartTypeName(model.name)}({');
      for (final field in model.fields.values) {
        buffer.writeln('    required this.${dartFieldName(field.name)},');
      }
      buffer.writeln('  });');
    }
    buffer.writeln();

    for (final field in model.fields.values) {
      _writeDoc(buffer, field.doc, indent: '  ');
      buffer.writeln('  final ${_dartType(field.type)} ${dartFieldName(field.name)};');
    }

    if (model.json) {
      buffer.writeln();
      buffer.writeln('  Map<String, dynamic> toJson() => <String, dynamic>{');
      for (final field in model.fields.values) {
        buffer.writeln(
          '    ${dartStringLiteral(field.name)}: ${_toJsonExpression(field.type, dartFieldName(field.name))},',
        );
      }
      buffer.writeln('  };');
      buffer.writeln();
      buffer.writeln(
        '  factory ${dartTypeName(model.name)}.fromJson(Map<String, dynamic> json) => ${dartTypeName(model.name)}(',
      );
      for (final field in model.fields.values) {
        final jsonAccess = "json[${dartStringLiteral(field.name)}]";
        buffer.writeln('    ${dartFieldName(field.name)}: ${_fromJsonExpression(field.type, jsonAccess)},');
      }
      buffer.writeln('  );');
    }

    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeMapping(StringBuffer buffer, MappingDef mapping) {
    final fromModel = resolved.dataModel(mapping.from);
    final toModel = resolved.dataModel(mapping.to);
    buffer.writeln('extension ${_mappingExtensionName(mapping.from, mapping.to)} on ${dartTypeName(mapping.from)} {');
    buffer.writeln('  ${dartTypeName(mapping.to)} ${_mappingMethodName(mapping.to)}() {');
    buffer.writeln('    final source = this;');
    buffer.writeln('    return ${dartTypeName(mapping.to)}(');
    for (final targetField in toModel.fields.values) {
      final fieldMapping = mapping.fields[targetField.name];
      final expression = fieldMapping == null
          ? _mappedFieldExpression(fromModel.fields[targetField.name]!, targetField)
          : _explicitFieldExpression(fromModel, targetField, fieldMapping);
      buffer.writeln('      ${dartFieldName(targetField.name)}: $expression,');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  String _explicitFieldExpression(DataModelDef fromModel, FieldDef targetField, FieldMapping mapping) {
    if (mapping.hasConst) {
      return _dartConstant(mapping.constValue);
    }
    return _mappedFieldExpression(
      fromModel.fields[mapping.fromField]!,
      targetField,
      converterName: mapping.converterName,
    );
  }

  String _mappedFieldExpression(FieldDef sourceField, FieldDef targetField, {String? converterName}) {
    final access = 'source.${dartFieldName(sourceField.name)}';
    return _convertExpression(sourceField.type, targetField.type, access, converterName: converterName);
  }

  String _convertExpression(TypeRef from, TypeRef to, String sourceExpression, {String? converterName}) {
    if (converterName == null && from.sameShape(to)) {
      return sourceExpression;
    }
    if (from.nullable && to.nullable) {
      return '$sourceExpression == null ? null : '
          '${_convertNonNull(from.nonNullable, to.nonNullable, '$sourceExpression!', converterName: converterName)}';
    }
    return _convertNonNull(from.nonNullable, to.nonNullable, sourceExpression, converterName: converterName);
  }

  String _convertNonNull(TypeRef from, TypeRef to, String sourceExpression, {String? converterName}) {
    if (converterName == 'default') {
      final converter = resolved.defaultConverterFor(from, to);
      if (converter != null) {
        return _converterCall(converter, sourceExpression);
      }
    } else if (converterName != null) {
      final converter = resolved.converterByName(converterName);
      if (converter == null) {
        throw StateError('No Dart converter named $converterName.');
      }
      return _converterCall(converter, sourceExpression);
    }
    if (from.sameShape(to, includeNullability: false)) {
      return sourceExpression;
    }
    if (from.isList && to.isList) {
      final itemExpression = _convertExpression(from.item!, to.item!, 'item');
      return '$sourceExpression.map((item) => $itemExpression).toList()';
    }
    if (_isNumeric(from) && _isNumeric(to)) {
      return switch (to.name) {
        'int' || 'long' => '$sourceExpression.toInt()',
        'double' || 'decimal' => '$sourceExpression.toDouble()',
        _ => sourceExpression,
      };
    }
    if (resolved.isEnum(from.name) && to.name == 'String') {
      return '${_enumToStringName(from.name)}($sourceExpression)';
    }
    if (from.name == 'String' && resolved.isEnum(to.name)) {
      return '${_enumFromStringName(to.name)}($sourceExpression)';
    }
    if (resolved.isEnum(from.name) && to.name == 'int') {
      return '${_enumToIntName(from.name)}($sourceExpression)';
    }
    if (from.name == 'int' && resolved.isEnum(to.name)) {
      return '${_enumFromIntName(to.name)}($sourceExpression)';
    }
    if (resolved.isDataModel(from.name) && resolved.isDataModel(to.name) && resolved.mappingFor(from, to) != null) {
      return '$sourceExpression.${_mappingMethodName(to.name)}()';
    }

    final converter = resolved.converterFor(from, to);
    if (converter != null) {
      return _converterCall(converter, sourceExpression);
    }

    throw StateError('No Dart conversion from $from to $to.');
  }

  String _toJsonExpression(TypeRef type, String expression) {
    if (type.nullable) {
      return '$expression == null ? null : ${_toJsonExpression(type.nonNullable, '$expression!')}';
    }
    if (type.isList) {
      return '$expression.map((item) => ${_toJsonExpression(type.item!, 'item')}).toList()';
    }
    if (resolved.isDataModel(type.name)) {
      return '$expression.toJson()';
    }
    if (resolved.isEnum(type.name)) {
      return _enumUsesStringJson(resolved.enumModel(type.name))
          ? '${_enumToStringName(type.name)}($expression)'
          : '${_enumToIntName(type.name)}($expression)';
    }
    if (type.name == 'DateTime') {
      return _jsonToStringExpression(type, expression);
    }
    return expression;
  }

  String _fromJsonExpression(TypeRef type, String expression) {
    if (type.nullable) {
      return '$expression == null ? null : ${_fromJsonExpression(type.nonNullable, expression)}';
    }
    if (type.isList) {
      return '($expression as List<dynamic>).map((item) => ${_fromJsonExpression(type.item!, 'item')}).toList()';
    }
    if (resolved.isDataModel(type.name)) {
      return '${dartTypeName(type.name)}.fromJson($expression as Map<String, dynamic>)';
    }
    if (resolved.isEnum(type.name)) {
      return _enumUsesStringJson(resolved.enumModel(type.name))
          ? '${_enumFromStringName(type.name)}($expression as String)'
          : '${_enumFromIntName(type.name)}($expression as int)';
    }
    return switch (type.name) {
      'String' => '$expression as String',
      'bool' => '$expression as bool',
      'int' || 'long' => '$expression as int',
      'double' || 'decimal' => '($expression as num).toDouble()',
      'num' => '$expression as num',
      'DateTime' => _jsonFromStringExpression(type, '$expression as String'),
      _ => throw StateError('No Dart JSON conversion for $type.'),
    };
  }

  String _dartType(TypeRef type) {
    final base = type.isList ? 'List<${_dartType(type.item!)}>' : _dartBaseType(type.name);
    return type.nullable ? '$base?' : base;
  }

  String _dartBaseType(String name) {
    return switch (name) {
      'decimal' => 'double',
      'long' => 'int',
      'String' || 'bool' || 'int' || 'double' || 'num' || 'DateTime' => name,
      _ => dartTypeName(name),
    };
  }

  String _dartConstant(Object? value) {
    return switch (value) {
      null => 'null',
      String() => dartStringLiteral(value),
      bool() || int() || double() => value.toString(),
      _ => throw StateError('Unsupported Dart constant $value.'),
    };
  }

  bool _isNumeric(TypeRef type) => {'int', 'long', 'double', 'num', 'decimal'}.contains(type.name);

  String _jsonToStringExpression(TypeRef type, String sourceExpression) {
    final converter = resolved.converterFor(type, const TypeRef(name: 'String', nullable: false));
    if (converter == null) {
      throw StateError('No Dart JSON converter from $type to String.');
    }
    return _converterCall(converter, sourceExpression);
  }

  String _jsonFromStringExpression(TypeRef type, String sourceExpression) {
    final converter = resolved.converterFor(const TypeRef(name: 'String', nullable: false), type);
    if (converter == null) {
      throw StateError('No Dart JSON converter from String to $type.');
    }
    return _converterCall(converter, sourceExpression);
  }

  String _converterCall(ConverterDef converter, String sourceExpression) {
    _usedConverters.add(converter);
    final methodName = _converterMethodNames[converter] ?? dartConverterBaseMethodName(converter);
    return 'MostMapperConverters.$methodName($sourceExpression)';
  }

  bool _enumHasStrings(EnumModelDef enumDef) => enumDef.values.values.every((value) => value.stringValue != null);

  bool _enumHasInts(EnumModelDef enumDef) => enumDef.values.values.every((value) => value.intValue != null);

  bool _enumUsesStringJson(EnumModelDef enumDef) => _enumHasStrings(enumDef);

  String _enumToStringName(String enumName) => '${dartFieldName(enumName)}ToString';

  String _enumFromStringName(String enumName) => '${dartFieldName(enumName)}FromString';

  String _enumToIntName(String enumName) => '${dartFieldName(enumName)}ToInt';

  String _enumFromIntName(String enumName) => '${dartFieldName(enumName)}FromInt';

  String _mappingExtensionName(String from, String to) => '${dartTypeName(from)}To${dartTypeName(to)}';

  String _mappingMethodName(String to) => 'to${dartTypeName(to)}';

  void _writeDoc(StringBuffer buffer, String? doc, {String indent = ''}) {
    if (doc == null || doc.isEmpty) {
      return;
    }
    for (final line in doc.split('\n')) {
      buffer.writeln('$indent/// $line');
    }
  }
}
