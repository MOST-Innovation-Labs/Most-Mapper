import 'package:yaml/yaml.dart';

import 'schema.dart';
import 'type_parser.dart';

/// Parses a YAML mapping document into a [MapperSchema].
MapperSchema parseMappingYaml(
  String source, {
  String sourceName = 'mapping.yaml',
}) {
  final document = loadYaml(source);
  if (document is! YamlMap) {
    throw MapperException('$sourceName must contain a YAML map.');
  }

  return MapperSchema(
    models: _parseModels(document['models'], sourceName),
    converters: _parseConverters(document['converters'], sourceName),
    mappings: _parseMappings(document['mappings'], sourceName),
  );
}

Map<String, ModelDef> _parseModels(Object? value, String sourceName) {
  if (value is! YamlMap) {
    throw MapperException('$sourceName must contain a models map.');
  }

  final models = <String, ModelDef>{};
  for (final entry in value.entries) {
    final name = _stringKey(entry.key, 'model name');
    final body = _mapValue(entry.value, 'model $name');
    final doc = _optionalString(body['doc'], 'models.$name.doc');

    if (body.containsKey('enum')) {
      if (body.containsKey('union')) {
        throw MapperException(
          'models.$name must contain exactly one of enum or union.',
        );
      }
      models[name] = EnumModelDef(
        name: name,
        doc: doc,
        values: _parseEnumValues(body['enum'], name),
      );
      continue;
    }

    if (body.containsKey('union')) {
      final union = _mapValue(body['union'], 'models.$name.union');
      models[name] = UnionModelDef(
        name: name,
        doc: doc,
        json: _optionalBool(body['json'], 'models.$name.json') ?? false,
        discriminator:
            _optionalString(
              union['discriminator'],
              'models.$name.union.discriminator',
            ) ??
            'Type',
        variants: _parseUnionVariants(union['variants'], name),
      );
      continue;
    }

    models[name] = DataModelDef(
      name: name,
      doc: doc,
      json: _optionalBool(body['json'], 'models.$name.json') ?? false,
      fields: _parseFields(body['fields'], name),
    );
  }
  return models;
}

Map<String, UnionVariantDef> _parseUnionVariants(
  Object? value,
  String modelName,
) {
  if (value is! YamlMap) {
    throw MapperException('models.$modelName.union.variants must be a map.');
  }

  final variants = <String, UnionVariantDef>{};
  for (final entry in value.entries) {
    final name = _stringKey(entry.key, 'union variant name');
    final body = _mapValue(
      entry.value,
      'models.$modelName.union.variants.$name',
    );
    variants[name] = UnionVariantDef(
      name: name,
      value: _requiredString(
        body['value'],
        'models.$modelName.union.variants.$name.value',
      ),
      fields: body.containsKey('fields')
          ? _parseFields(body['fields'], '$modelName.union.variants.$name')
          : {},
    );
  }
  return variants;
}

Map<String, EnumValueDef> _parseEnumValues(Object? value, String modelName) {
  if (value is! YamlMap) {
    throw MapperException('models.$modelName.enum must be a map.');
  }

  final values = <String, EnumValueDef>{};
  for (final entry in value.entries) {
    final name = _stringKey(entry.key, 'enum value name');
    final body = _mapValue(entry.value, 'models.$modelName.enum.$name');
    values[name] = EnumValueDef(
      name: name,
      stringValue: _optionalString(
        body['string'],
        'models.$modelName.enum.$name.string',
      ),
      intValue: _optionalInt(body['int'], 'models.$modelName.enum.$name.int'),
    );
  }
  return values;
}

Map<String, FieldDef> _parseFields(Object? value, String modelName) {
  if (value is! YamlMap) {
    throw MapperException('models.$modelName.fields must be a map.');
  }

  final fields = <String, FieldDef>{};
  for (final entry in value.entries) {
    final name = _stringKey(entry.key, 'field name');
    final raw = entry.value;

    if (raw is String) {
      fields[name] = FieldDef(name: name, type: parseType(raw), doc: null);
      continue;
    }

    final body = _mapValue(raw, 'models.$modelName.fields.$name');
    final typeText = _requiredString(
      body['type'],
      'models.$modelName.fields.$name.type',
    );
    final nullable =
        _optionalBool(
          body['nullable'],
          'models.$modelName.fields.$name.nullable',
        ) ??
        false;
    final parsedType = parseType(typeText);
    fields[name] = FieldDef(
      name: name,
      type: nullable ? parsedType.withNullable(true) : parsedType,
      doc: _optionalString(body['doc'], 'models.$modelName.fields.$name.doc'),
    );
  }
  return fields;
}

List<ConverterDef> _parseConverters(Object? value, String sourceName) {
  if (value == null) {
    return [];
  }
  if (value is! YamlList) {
    throw MapperException('$sourceName converters must be a list.');
  }

  final converters = <ConverterDef>[];
  for (var index = 0; index < value.length; index++) {
    final body = _mapValue(value[index], 'converters[$index]');
    converters.add(
      ConverterDef(
        name: _optionalString(body['name'], 'converters[$index].name'),
        from: parseType(
          _requiredString(body['from'], 'converters[$index].from'),
        ),
        to: parseType(_requiredString(body['to'], 'converters[$index].to')),
        dart: _parseDartCodeSpec(body['dart'], index),
        csharp: _parseCSharpCodeSpec(body['csharp'], index),
      ),
    );
  }
  return converters;
}

DartCodeSpec _parseDartCodeSpec(Object? value, int index) {
  final body = _mapValue(value, 'converters[$index].dart');
  return DartCodeSpec(
    imports: _optionalStringList(
      body['imports'],
      'converters[$index].dart.imports',
    ),
    expression: _requiredString(
      body['expression'],
      'converters[$index].dart.expression',
    ),
  );
}

CSharpCodeSpec _parseCSharpCodeSpec(Object? value, int index) {
  final body = _mapValue(value, 'converters[$index].csharp');
  return CSharpCodeSpec(
    usings: _optionalStringList(
      body['usings'],
      'converters[$index].csharp.usings',
    ),
    expression: _requiredString(
      body['expression'],
      'converters[$index].csharp.expression',
    ),
  );
}

List<MappingDef> _parseMappings(Object? value, String sourceName) {
  if (value == null) {
    return [];
  }
  if (value is! YamlList) {
    throw MapperException('$sourceName mappings must be a list.');
  }

  final mappings = <MappingDef>[];
  for (var index = 0; index < value.length; index++) {
    final body = _mapValue(value[index], 'mappings[$index]');
    mappings.add(
      MappingDef(
        from: _requiredString(body['from'], 'mappings[$index].from'),
        to: _requiredString(body['to'], 'mappings[$index].to'),
        fields: _parseMappingFields(body['fields'], index),
      ),
    );
  }
  return mappings;
}

Map<String, FieldMapping> _parseMappingFields(Object? value, int mappingIndex) {
  if (value == null) {
    return {};
  }
  if (value is! YamlMap) {
    throw MapperException('mappings[$mappingIndex].fields must be a map.');
  }

  final fields = <String, FieldMapping>{};
  for (final entry in value.entries) {
    final targetName = _stringKey(entry.key, 'mapping target field');
    final body = _mapValue(
      entry.value,
      'mappings[$mappingIndex].fields.$targetName',
    );
    final hasFrom = body.containsKey('from');
    final hasConst = body.containsKey('const');
    final hasParameter = body.containsKey('parameter');
    final assignmentCount = [
      hasFrom,
      hasConst,
      hasParameter,
    ].where((value) => value).length;
    if (assignmentCount != 1) {
      throw MapperException(
        'mappings[$mappingIndex].fields.$targetName must contain exactly one of from, const, or parameter.',
      );
    }
    if (hasFrom) {
      fields[targetName] = FieldMapping.from(
        _requiredString(
          body['from'],
          'mappings[$mappingIndex].fields.$targetName.from',
        ),
        converterName: _optionalString(
          body['converter'],
          'mappings[$mappingIndex].fields.$targetName.converter',
        ),
      );
      continue;
    }
    if (hasParameter) {
      fields[targetName] = FieldMapping.parameter(
        parseType(
          _requiredString(
            body['parameter'],
            'mappings[$mappingIndex].fields.$targetName.parameter',
          ),
        ),
        converterName: _optionalString(
          body['converter'],
          'mappings[$mappingIndex].fields.$targetName.converter',
        ),
      );
      continue;
    }
    fields[targetName] = FieldMapping.constant(body['const']);
  }
  return fields;
}

String _stringKey(Object? value, String context) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw MapperException('$context must be a non-empty string.');
}

YamlMap _mapValue(Object? value, String context) {
  if (value is YamlMap) {
    return value;
  }
  throw MapperException('$context must be a map.');
}

String _requiredString(Object? value, String context) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw MapperException('$context must be a non-empty string.');
}

String? _optionalString(Object? value, String context) {
  if (value == null) {
    return null;
  }
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw MapperException('$context must be a non-empty string.');
}

bool? _optionalBool(Object? value, String context) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw MapperException('$context must be a bool.');
}

int? _optionalInt(Object? value, String context) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw MapperException('$context must be an int.');
}

List<String> _optionalStringList(Object? value, String context) {
  if (value == null) {
    return [];
  }
  if (value is! YamlList) {
    throw MapperException('$context must be a list.');
  }
  return [
    for (final item in value)
      if (item is String)
        item
      else
        throw MapperException('$context must contain only strings.'),
  ];
}
