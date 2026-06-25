import 'names.dart';
import 'resolver.dart';
import 'schema.dart';
import 'text_helpers.dart';
import 'type_system.dart';

String emitCSharp(ResolvedSchema resolved) {
  final emitter = _CSharpEmitter(resolved);
  return emitter.emit();
}

class _CSharpEmitter {
  _CSharpEmitter(this.resolved);

  final ResolvedSchema resolved;
  var _converterMethodNames = <ConverterDef, String>{};

  String emit() {
    final converters = resolved.convertersToEmit(resolved.usedConverters());
    _converterMethodNames = csharpConverterMethodNames(converters);
    final body = _buildBody();

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.');
    buffer.writeln('#nullable enable');
    buffer.writeln();

    final usings = <String>{'System', 'System.Collections.Generic', 'System.Linq', 'System.Text.Json'};
    for (final converter in converters) {
      usings.addAll(converter.csharp.usings);
    }
    for (final using in usings.toList()..sort()) {
      buffer.writeln('using $using;');
    }
    buffer.writeln();

    _writeConverters(buffer, converters);
    buffer.write(body);

    return buffer.toString();
  }

  StringBuffer _buildBody() {
    final body = StringBuffer();
    if (resolved.dataModels.any((model) => model.json)) {
      _writeJsonHelper(body);
    }
    for (final enumDef in resolved.enumModels) {
      _writeEnum(body, enumDef);
    }
    for (final model in resolved.dataModels) {
      _writeDataModel(body, model);
    }
    if (resolved.schema.mappings.isNotEmpty) {
      _writeMappings(body);
    }
    return body;
  }

  void _writeJsonHelper(StringBuffer buffer) {
    buffer.writeln('internal static class MappingJson');
    buffer.writeln('{');
    buffer.writeln('    public static JsonElement? Optional(JsonElement json, string name)');
    buffer.writeln('    {');
    buffer.writeln(
      '        return json.TryGetProperty(name, out var value) && '
      'value.ValueKind != JsonValueKind.Null ? value : null;',
    );
    buffer.writeln('    }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeConverters(StringBuffer buffer, List<ConverterDef> converters) {
    if (converters.isEmpty) {
      return;
    }
    buffer.writeln('public static class MappingConverters');
    buffer.writeln('{');
    for (final converter in converters) {
      final methodName = _converterMethodNames[converter] ?? csharpConverterBaseMethodName(converter);
      buffer.writeln(
        '    public static ${_csharpType(converter.to)} $methodName(${_csharpType(converter.from)} source)',
      );
      buffer.writeln('    {');
      _writeReturnExpression(buffer, indent: '    ', expression: converter.csharp.expression);
      buffer.writeln('    }');
      buffer.writeln();
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeEnum(StringBuffer buffer, EnumModelDef enumDef) {
    _writeDoc(buffer, enumDef.doc);
    buffer.writeln('public enum ${csharpTypeName(enumDef.name)}');
    buffer.writeln('{');
    for (final value in enumDef.values.values) {
      buffer.writeln('    ${csharpEnumValueName(value.name)},');
    }
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('public static class ${_enumHelperName(enumDef.name)}');
    buffer.writeln('{');
    if (resolved.enumHasStrings(enumDef)) {
      buffer.writeln('    public static string ToStringValue(${csharpTypeName(enumDef.name)} value) => value switch');
      buffer.writeln('    {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '        ${csharpTypeName(enumDef.name)}.${csharpEnumValueName(value.name)} => '
          '${csharpStringLiteral(value.stringValue!)},',
        );
      }
      buffer.writeln('        _ => throw new ArgumentOutOfRangeException(nameof(value)),');
      buffer.writeln('    };');
      buffer.writeln();

      buffer.writeln('    public static ${csharpTypeName(enumDef.name)} FromStringValue(string value) => value switch');
      buffer.writeln('    {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '        ${csharpStringLiteral(value.stringValue!)} => '
          '${csharpTypeName(enumDef.name)}.${csharpEnumValueName(value.name)},',
        );
      }
      buffer.writeln(
        '        _ => throw new ArgumentOutOfRangeException(nameof(value), value, '
        '${csharpStringLiteral('Unknown ${csharpTypeName(enumDef.name)} string')}),',
      );
      buffer.writeln('    };');
      buffer.writeln();
    }

    if (resolved.enumHasInts(enumDef)) {
      buffer.writeln('    public static int ToIntValue(${csharpTypeName(enumDef.name)} value) => value switch');
      buffer.writeln('    {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '        ${csharpTypeName(enumDef.name)}.${csharpEnumValueName(value.name)} => ${value.intValue},',
        );
      }
      buffer.writeln('        _ => throw new ArgumentOutOfRangeException(nameof(value)),');
      buffer.writeln('    };');
      buffer.writeln();

      buffer.writeln('    public static ${csharpTypeName(enumDef.name)} FromIntValue(int value) => value switch');
      buffer.writeln('    {');
      for (final value in enumDef.values.values) {
        buffer.writeln(
          '        ${value.intValue} => ${csharpTypeName(enumDef.name)}.${csharpEnumValueName(value.name)},',
        );
      }
      buffer.writeln(
        '        _ => throw new ArgumentOutOfRangeException(nameof(value), value, '
        '${csharpStringLiteral('Unknown ${csharpTypeName(enumDef.name)} int')}),',
      );
      buffer.writeln('    };');
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeDataModel(StringBuffer buffer, DataModelDef model) {
    _writeDoc(buffer, model.doc);
    buffer.writeln('public class ${csharpTypeName(model.name)}');
    buffer.writeln('{');
    for (final field in model.fields.values) {
      _writeDoc(buffer, field.doc, indent: '    ');
      buffer.writeln(
        '    public ${_csharpType(field.type)} ${csharpPropertyName(field.name)} '
        '{ get; set; }${_propertyDefault(field.type)}',
      );
    }

    if (model.json) {
      buffer.writeln();
      buffer.writeln('    public Dictionary<string, object?> ToJsonMap()');
      buffer.writeln('    {');
      buffer.writeln('        return new Dictionary<string, object?>');
      buffer.writeln('        {');
      for (final field in model.fields.values) {
        buffer.writeln(
          '            [${csharpStringLiteral(field.name)}] = '
          '${_toJsonExpression(field.type, csharpPropertyName(field.name))},',
        );
      }
      buffer.writeln('        };');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    public string ToJson() => JsonSerializer.Serialize(ToJsonMap());');
      buffer.writeln();
      buffer.writeln('    public static ${csharpTypeName(model.name)} FromJson(string json)');
      buffer.writeln('    {');
      buffer.writeln('        using var document = JsonDocument.Parse(json);');
      buffer.writeln('        return FromJsonElement(document.RootElement);');
      buffer.writeln('    }');
      buffer.writeln();
      buffer.writeln('    public static ${csharpTypeName(model.name)} FromJsonElement(JsonElement json)');
      buffer.writeln('    {');
      buffer.writeln('        return new ${csharpTypeName(model.name)}');
      buffer.writeln('        {');
      for (final field in model.fields.values) {
        buffer.writeln('            ${csharpPropertyName(field.name)} = ${_fieldFromJsonExpression(field)},');
      }
      buffer.writeln('        };');
      buffer.writeln('    }');
    }

    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeMappings(StringBuffer buffer) {
    buffer.writeln('public static class MappingExtensions');
    buffer.writeln('{');
    for (final mapping in resolved.schema.mappings) {
      buffer.writeln('    public static ${csharpTypeName(mapping.to)} ${_mappingMethodName(mapping.to)}(');
      buffer.writeln('        this ${csharpTypeName(mapping.from)} source)');
      buffer.writeln('    {');
      buffer.writeln('        return new ${csharpTypeName(mapping.to)}');
      buffer.writeln('        {');
      for (final assignment in resolved.mappingAssignments(mapping)) {
        buffer.writeln(
          '            ${csharpPropertyName(assignment.targetField.name)} = ${_assignmentExpression(assignment)},',
        );
      }
      buffer.writeln('        };');
      buffer.writeln('    }');
      buffer.writeln();
    }
    buffer.writeln('}');
    buffer.writeln();
  }

  void _writeReturnExpression(StringBuffer buffer, {required String indent, required String expression}) {
    final trimmed = expression.trim();
    if (!trimmed.contains('\n')) {
      buffer.writeln('$indent    return ($trimmed);');
      return;
    }

    buffer.writeln('$indent    return (');
    for (final line in trimmed.split('\n')) {
      buffer.writeln('$indent        ${line.trimRight()}');
    }
    buffer.writeln('$indent    );');
  }

  String _assignmentExpression(ResolvedFieldAssignment assignment) {
    return switch (assignment) {
      ResolvedConstantFieldAssignment(:final constValue) => _csharpConstant(constValue),
      ResolvedSourceFieldAssignment(:final sourceField, :final conversion) => _convertExpression(
        conversion,
        'source.${csharpPropertyName(sourceField.name)}',
      ),
    };
  }

  String _convertExpression(ConversionPlan conversion, String sourceExpression) {
    return switch (conversion) {
      IdentityConversionPlan() => sourceExpression,
      NullableConversionPlan(:final from, :final inner) =>
        '$sourceExpression == null ? null : ${_convertExpression(inner, _nonNullAccess(from, sourceExpression))}',
      ListConversionPlan(:final item) =>
        '$sourceExpression.Select(item => ${_convertExpression(item, 'item')}).ToList()',
      NumericConversionPlan(:final to) => switch (to.name) {
        'int' => '(int)$sourceExpression',
        'long' => '(long)$sourceExpression',
        'double' || 'num' => '(double)$sourceExpression',
        'decimal' => '(decimal)$sourceExpression',
        _ => sourceExpression,
      },
      EnumScalarConversionPlan(:final enumName, :final kind, :final fromEnum) => _enumScalarExpression(
        enumName,
        kind,
        fromEnum,
        sourceExpression,
      ),
      ModelMappingConversionPlan(:final mapping) => '$sourceExpression.${_mappingMethodName(mapping.to)}()',
      ConverterConversionPlan(:final converter) => _converterCall(converter, sourceExpression),
    };
  }

  String _toJsonExpression(TypeRef type, String expression) {
    if (type.nullable) {
      final nonNull = _nonNullAccess(type, expression);
      return '$expression == null ? null : ${_toJsonExpression(type.nonNullable, nonNull)}';
    }
    if (type.isList) {
      return '$expression.Select(item => ${_toJsonExpression(type.item!, 'item')}).ToList()';
    }
    if (resolved.isDataModel(type.name)) {
      return '$expression.ToJsonMap()';
    }
    if (resolved.isEnum(type.name)) {
      return resolved.enumUsesStringJson(resolved.enumModel(type.name))
          ? '${_enumHelperName(type.name)}.ToStringValue($expression)'
          : '${_enumHelperName(type.name)}.ToIntValue($expression)';
    }
    if (type.name == dateTimeType.name) {
      return _jsonToStringExpression(type, expression);
    }
    return expression;
  }

  String _fieldFromJsonExpression(FieldDef field) {
    final key = csharpStringLiteral(field.name);
    if (field.type.nullable) {
      final localName = '${lowerFirst(csharpPropertyName(field.name))}Json';
      return 'MappingJson.Optional(json, $key) is JsonElement $localName '
          '? ${_fromJsonExpression(field.type.nonNullable, localName)} : null';
    }
    return _fromJsonExpression(field.type, 'json.GetProperty($key)');
  }

  String _fromJsonExpression(TypeRef type, String expression) {
    if (type.isList) {
      return '$expression.EnumerateArray().Select(item => ${_fromJsonExpression(type.item!, 'item')}).ToList()';
    }
    if (resolved.isDataModel(type.name)) {
      return '${csharpTypeName(type.name)}.FromJsonElement($expression)';
    }
    if (resolved.isEnum(type.name)) {
      return resolved.enumUsesStringJson(resolved.enumModel(type.name))
          ? '${_enumHelperName(type.name)}.FromStringValue($expression.GetString()!)'
          : '${_enumHelperName(type.name)}.FromIntValue($expression.GetInt32())';
    }
    return switch (type.name) {
      'String' => '$expression.GetString()!',
      'bool' => '$expression.GetBoolean()',
      'int' => '$expression.GetInt32()',
      'long' => '$expression.GetInt64()',
      'double' || 'num' => '$expression.GetDouble()',
      'decimal' => '$expression.GetDecimal()',
      'DateTime' => _jsonFromStringExpression(type, '$expression.GetString()!'),
      _ => throw StateError('No C# JSON conversion for $type.'),
    };
  }

  String _csharpType(TypeRef type) {
    final base = type.isList ? 'List<${_csharpType(type.item!)}>' : _csharpBaseType(type.name);
    return type.nullable ? '$base?' : base;
  }

  String _csharpBaseType(String name) {
    return switch (name) {
      'String' => 'string',
      'bool' => 'bool',
      'int' => 'int',
      'long' => 'long',
      'double' || 'num' => 'double',
      'decimal' => 'decimal',
      'DateTime' => 'System.DateTime',
      _ => csharpTypeName(name),
    };
  }

  String _propertyDefault(TypeRef type) {
    if (type.nullable || _isValueType(type)) {
      return '';
    }
    if (type.isList) {
      return ' = new ${_csharpType(type)}();';
    }
    if (type.name == 'String') {
      return ' = "";';
    }
    return ' = default!;';
  }

  String _nonNullAccess(TypeRef type, String expression) {
    return _isValueType(type.nonNullable) ? '$expression.Value' : expression;
  }

  bool _isValueType(TypeRef type) {
    return type.name == 'bool' ||
        type.name == 'int' ||
        type.name == 'long' ||
        type.name == 'double' ||
        type.name == 'num' ||
        type.name == 'decimal' ||
        type.name == 'DateTime' ||
        resolved.isEnum(type.name);
  }

  String _csharpConstant(Object? value) {
    return switch (value) {
      null => 'null',
      String() => csharpStringLiteral(value),
      bool() => value ? 'true' : 'false',
      int() || double() => value.toString(),
      _ => throw StateError('Unsupported C# constant $value.'),
    };
  }

  String _jsonToStringExpression(TypeRef type, String sourceExpression) {
    final converter = resolved.converterFor(type, stringType);
    if (converter == null) {
      throw StateError('No C# JSON converter from $type to String.');
    }
    return _converterCall(converter, sourceExpression);
  }

  String _jsonFromStringExpression(TypeRef type, String sourceExpression) {
    final converter = resolved.converterFor(stringType, type);
    if (converter == null) {
      throw StateError('No C# JSON converter from String to $type.');
    }
    return _converterCall(converter, sourceExpression);
  }

  String _converterCall(ConverterDef converter, String sourceExpression) {
    final methodName = _converterMethodNames[converter] ?? csharpConverterBaseMethodName(converter);
    return 'MappingConverters.$methodName($sourceExpression)';
  }

  String _enumScalarExpression(String enumName, EnumScalarKind kind, bool fromEnum, String sourceExpression) {
    return switch ((kind, fromEnum)) {
      (EnumScalarKind.string, true) => '${_enumHelperName(enumName)}.ToStringValue($sourceExpression)',
      (EnumScalarKind.string, false) => '${_enumHelperName(enumName)}.FromStringValue($sourceExpression)',
      (EnumScalarKind.int, true) => '${_enumHelperName(enumName)}.ToIntValue($sourceExpression)',
      (EnumScalarKind.int, false) => '${_enumHelperName(enumName)}.FromIntValue($sourceExpression)',
    };
  }

  String _enumHelperName(String enumName) => '${csharpTypeName(enumName)}Conversions';

  String _mappingMethodName(String to) => 'To${csharpTypeName(to)}';

  void _writeDoc(StringBuffer buffer, String? doc, {String indent = ''}) {
    if (doc == null || doc.isEmpty) {
      return;
    }
    buffer.writeln('$indent/// <summary>');
    for (final line in doc.split('\n')) {
      buffer.writeln('$indent/// $line');
    }
    buffer.writeln('$indent/// </summary>');
  }
}
