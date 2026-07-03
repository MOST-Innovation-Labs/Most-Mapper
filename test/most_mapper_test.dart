import 'dart:io';

import 'package:most_mapper/most_mapper.dart';
import 'package:most_mapper/src/csharp_emitter.dart';
import 'package:most_mapper/src/dart_emitter.dart';
import 'package:most_mapper/src/resolver.dart';
import 'package:most_mapper/src/type_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'parses models, enums, converters, multiline expressions, mappings, and json flags',
    () {
      final schema = parseMappingYaml(_sampleYaml);
      final modelA = schema.models['ModelA']! as DataModelDef;
      final orderStatus = schema.models['OrderStatus']! as EnumModelDef;

      expect(modelA.json, isTrue);
      expect(modelA.fields['createdAt']!.type.nullable, isTrue);
      expect(modelA.fields['bs']!.type.item!.name, 'ModelB');
      expect(orderStatus.values['captured']!.stringValue, 'captured');
      expect(orderStatus.values['captured']!.intValue, 1);
      expect(schema.converters[0].name, isNull);
      expect(schema.converters[1].dart.expression, contains('\n'));
      expect(
        schema.mappings.first.fields['Datetime']!.converterName,
        'offsetDateTimeToString',
      );
      expect(schema.mappings.last.fields['SomeField']!.hasConst, isTrue);
    },
  );

  test(
    'validates default mapping, numeric casts, enum scalar conversions, and converters',
    () {
      final resolved = _resolvedSample();

      expect(
        resolved.canConvert(parseType('OrderStatus'), parseType('String')),
        isTrue,
      );
      expect(
        resolved.canConvert(parseType('OrderStatus'), parseType('int')),
        isTrue,
      );
      expect(
        resolved.canConvert(parseType('String'), parseType('OrderStatus')),
        isTrue,
      );
      expect(
        resolved.canConvert(parseType('int'), parseType('OrderStatus')),
        isTrue,
      );
      expect(
        resolved.canConvert(parseType('int'), parseType('decimal')),
        isTrue,
      );
      expect(
        resolved.canConvert(parseType('Measurement'), parseType('decimal')),
        isTrue,
      );
      expect(
        resolved.canConvert(
          parseType('List<ModelB>'),
          parseType('List<ModelBWire>'),
        ),
        isTrue,
      );
    },
  );

  test(
    'emits Dart models, JSON helpers, enum helpers, mapping extensions, casts, and converters',
    () {
      final output = emitDart(_resolvedSample());

      expect(output, contains('enum OrderStatus'));
      expect(output, contains('Map<String, dynamic> toJson()'));
      expect(output, contains('orderStatusToString(source.status)'));
      expect(output, contains('orderStatusToInt(source.status)'));
      expect(output, isNot(contains('_mappingDateTimeToJson')));
      expect(output, isNot(contains('_mappingDateTimeFromJson')));
      expect(
        output,
        contains(
          '// ignore_for_file: unnecessary_parenthesis, unused_element, avoid-high-cyclomatic-complexity',
        ),
      );
      expect(output, contains('class MappingConverters'));
      expect(
        output,
        isNot(contains('static String _dateTimeToString(DateTime source)')),
      );
      expect(
        output,
        isNot(contains('static DateTime stringToDateTime(String source)')),
      );
      expect(
        output,
        contains('static double measurementToDecimal(Measurement source)'),
      );
      expect(
        output,
        contains('return (source.value / pow(10, source.scale));'),
      );
      expect(
        output,
        contains('MappingConverters.offsetDateTimeToString(createdAt!)'),
      );
      expect(
        output,
        contains(
          "MappingConverters.offsetStringToDateTime(json['createdAt'] as String)",
        ),
      );
      expect(output, contains('extension ModelBToModelBWire on ModelB'));
      expect(output, contains('ModelBWire toModelBWire()'));
      expect(output, contains('item.toModelBWire()'));
      expect(output, contains('id: source.jsonFieldName'));
      expect(
        output,
        isNot(
          contains(
            'id: source.jsonFieldName == null ? null : source.jsonFieldName!',
          ),
        ),
      );
      expect(
        output,
        contains('MappingConverters.measurementToDecimal(source.reading)'),
      );
      expect(
        output,
        contains('MappingConverters.offsetDateTimeToString(source.datetime)'),
      );
      expect(output, contains('withoutOffsetUtc.subtract(offset)'));
      expect(output, contains('someField: null'));
    },
  );

  test(
    'emits C# models, JSON helpers, enum helpers, mapping extensions, casts, and converters',
    () {
      final output = emitCSharp(_resolvedSample());

      expect(output, contains('public enum OrderStatus'));
      expect(
        output,
        contains('public Dictionary<string, object?> ToJsonMap()'),
      );
      expect(
        output,
        contains('OrderStatusConversions.ToStringValue(source.Status)'),
      );
      expect(
        output,
        contains('OrderStatusConversions.ToIntValue(source.Status)'),
      );
      expect(output, isNot(contains('MappingJson.DateTimeToJson')));
      expect(output, isNot(contains('MappingJson.DateTimeFromJson')));
      expect(
        output,
        isNot(
          contains(
            'private static string DateTimeToString(System.DateTime source)',
          ),
        ),
      );
      expect(
        output,
        isNot(
          contains(
            'private static System.DateTime StringToDateTime(string source)',
          ),
        ),
      );
      expect(output, contains('public static class MappingConverters'));
      expect(
        output,
        contains(
          'public static decimal MeasurementToDecimal(Measurement source)',
        ),
      );
      expect(
        output,
        isNot(
          contains(
            'private static decimal MeasurementToDecimal(Measurement source)',
          ),
        ),
      );
      expect(
        output,
        contains('MappingConverters.OffsetDateTimeToString(CreatedAt.Value)'),
      );
      expect(
        output,
        contains(
          'MappingConverters.OffsetStringToDateTime(createdAtJson.GetString()!)',
        ),
      );
      expect(output, contains('public static ModelBWire ToModelBWire('));
      expect(output, contains('this ModelB source)'));
      expect(output, contains('item.ToModelBWire()'));
      expect(output, contains('Id = source.JsonFieldName'));
      expect(
        output,
        isNot(
          contains(
            'Id = source.JsonFieldName == null ? null : source.JsonFieldName',
          ),
        ),
      );
      expect(
        output,
        contains('MappingConverters.MeasurementToDecimal(source.Reading)'),
      );
      expect(
        output,
        contains('MappingConverters.OffsetDateTimeToString(source.Datetime)'),
      );
      expect(output, contains('DateTimeOffset.ParseExact('));
      expect(
        output,
        contains(
          'return (\n            DateTimeOffset.ParseExact(\n                source,',
        ),
      );
      expect(output, contains('SomeField = null'));
    },
  );

  test('rejects const null for non-nullable fields', () {
    final schema = parseMappingYaml('''
models:
  A:
    fields:
      value: String
  B:
    fields:
      value: String
mappings:
  - from: A
    to: B
    fields:
      value: { const: null }
''');

    expect(
      () => ResolvedSchema(schema).validate(),
      throwsA(isA<MapperException>()),
    );
  });

  test('supports parameter mapping fields with enum scalar conversion', () {
    final schema = parseMappingYaml('''
models:
  EnumType:
    enum:
      a: { string: a }
      b: { string: b }
      c: { string: c }
  Source:
    fields:
      id: String
  Target:
    fields:
      enumField: String
mappings:
  - from: Source
    to: Target
    fields:
      enumField: { parameter: EnumType }
''');

    final fieldMapping = schema.mappings.single.fields['enumField']!;
    expect(fieldMapping.parameterType!.name, 'EnumType');

    final resolved = ResolvedSchema(schema);
    expect(() => resolved.validate(), returnsNormally);

    final dart = emitDart(resolved);
    expect(dart, contains('Target toTarget({'));
    expect(dart, contains('required EnumType enumField,'));
    expect(dart, contains('enumField: enumTypeToString(enumField)'));

    final csharp = emitCSharp(resolved);
    expect(csharp, contains('public static Target ToTarget('));
    expect(csharp, contains('this Source source,'));
    expect(csharp, contains('EnumType enumField)'));
    expect(
      csharp,
      contains('EnumField = EnumTypeConversions.ToStringValue(enumField)'),
    );
  });

  test('supports named converters for parameter mapping fields', () {
    final resolved = ResolvedSchema(
      parseMappingYaml('''
models:
  Source:
    fields:
      id: String
  Target:
    fields:
      value: String
converters:
  - name: intText
    from: int
    to: String
    dart:
      expression: "source.toString()"
    csharp:
      expression: "source.ToString()"
mappings:
  - from: Source
    to: Target
    fields:
      value: { parameter: int, converter: intText }
'''),
    );

    expect(() => resolved.validate(), returnsNormally);

    final dart = emitDart(resolved);
    expect(dart, contains('static String intText(int source)'));
    expect(dart, contains('value: MappingConverters.intText(value)'));

    final csharp = emitCSharp(resolved);
    expect(csharp, contains('public static string IntText(int source)'));
    expect(csharp, contains('Value = MappingConverters.IntText(value)'));
  });

  test('renames parameter mapping fields that shadow generated locals', () {
    final resolved = ResolvedSchema(
      parseMappingYaml('''
models:
  SqsSource:
    enum:
      pos: { string: pos }
      relay: { string: relay }
  Payload:
    fields:
      id: String
  Message:
    fields:
      Source: String
      id: String
mappings:
  - from: Payload
    to: Message
    fields:
      Source: { parameter: SqsSource }
'''),
    );

    expect(() => resolved.validate(), returnsNormally);

    final dart = emitDart(resolved);
    expect(dart, contains('required SqsSource sourceParam,'));
    expect(dart, contains('final source = this;'));
    expect(dart, contains('source: sqsSourceToString(sourceParam)'));
    expect(dart, contains('id: source.id'));
    expect(dart, isNot(contains('mappingSource')));

    final csharp = emitCSharp(resolved);
    expect(csharp, contains('this Payload source,'));
    expect(csharp, contains('SqsSource sourceParam)'));
    expect(
      csharp,
      contains('Source = SqsSourceConversions.ToStringValue(sourceParam)'),
    );
    expect(csharp, contains('Id = source.Id'));
    expect(csharp, isNot(contains('mappingSource')));
  });

  test('rejects unknown parameter mapping types', () {
    final schema = parseMappingYaml('''
models:
  Source:
    fields:
      id: String
  Target:
    fields:
      value: String
mappings:
  - from: Source
    to: Target
    fields:
      value: { parameter: MissingType }
''');

    expect(
      () => ResolvedSchema(schema).validate(),
      throwsA(isA<MapperException>()),
    );
  });

  test('rejects nullable parameter mapping to non-nullable target fields', () {
    final schema = parseMappingYaml('''
models:
  Source:
    fields:
      id: String
  Target:
    fields:
      value: String
mappings:
  - from: Source
    to: Target
    fields:
      value: { parameter: String? }
''');

    expect(
      () => ResolvedSchema(schema).validate(),
      throwsA(isA<MapperException>()),
    );
  });

  test('does not use parameterized mappings for implicit model conversion', () {
    final schema = parseMappingYaml('''
models:
  Inner:
    fields:
      value: String
  InnerWire:
    fields:
      value: String
      extra: String
  Outer:
    fields:
      child: Inner
  OuterWire:
    fields:
      child: InnerWire
mappings:
  - from: Inner
    to: InnerWire
    fields:
      extra: { parameter: String }
  - from: Outer
    to: OuterWire
''');

    expect(
      () => ResolvedSchema(schema).validate(),
      throwsA(isA<MapperException>()),
    );
  });

  test('uses default DateTime ISO converters for json DateTime fields', () {
    final schema = parseMappingYaml('''
models:
  A:
    json: true
    fields:
      createdAt: DateTime
''');

    final resolved = ResolvedSchema(schema);

    expect(() => resolved.validate(), returnsNormally);
    expect(
      resolved.converterFor(parseType('DateTime'), parseType('String'))!.name,
      isNull,
    );
    expect(emitDart(resolved), contains('source.toUtc().toIso8601String()'));
    expect(
      emitCSharp(resolved),
      contains(
        'ToString("yyyy-MM-dd\'T\'HH:mm:ss\'Z\'", System.Globalization.CultureInfo.InvariantCulture)',
      ),
    );
  });

  test('emits long as Dart int and C# long', () {
    final resolved = ResolvedSchema(
      parseMappingYaml('''
models:
  A:
    json: true
    fields:
      epochMilliseconds: long
'''),
    );

    expect(() => resolved.validate(), returnsNormally);
    expect(emitDart(resolved), contains('final int epochMilliseconds;'));
    expect(
      emitDart(resolved),
      contains("epochMilliseconds: json['epochMilliseconds'] as int"),
    );
    expect(
      emitCSharp(resolved),
      contains('public long EpochMilliseconds { get; set; }'),
    );
    expect(
      emitCSharp(resolved),
      contains(
        'EpochMilliseconds = json.GetProperty("epochMilliseconds").GetInt64()',
      ),
    );
  });

  test('allows unnamed converters and converter default selector', () {
    final schema = parseMappingYaml('''
models:
  A:
    fields:
      value: DateTime
  B:
    fields:
      defaultValue: String
      implicitValue: String
converters:
  - from: DateTime
    to: String
    dart:
      expression: "'custom'"
    csharp:
      expression: '"custom"'
mappings:
  - from: A
    to: B
    fields:
      defaultValue: { from: value, converter: default }
      implicitValue: { from: value }
''');

    expect(schema.converters.single.name, isNull);

    final resolved = ResolvedSchema(schema);
    resolved.validate();

    final dart = emitDart(resolved);
    expect(dart, contains('static String dateTimeToString(DateTime source)'));
    expect(dart, contains('static String dateTimeToString2(DateTime source)'));
    expect(
      dart,
      contains(
        'defaultValue: MappingConverters.dateTimeToString(source.value)',
      ),
    );
    expect(
      dart,
      contains(
        'implicitValue: MappingConverters.dateTimeToString2(source.value)',
      ),
    );
    expect(
      dart,
      isNot(contains('static DateTime stringToDateTime(String source)')),
    );

    final csharp = emitCSharp(resolved);
    expect(
      csharp,
      contains('public static string DateTimeToString(System.DateTime source)'),
    );
    expect(
      csharp,
      contains(
        'public static string DateTimeToString2(System.DateTime source)',
      ),
    );
    expect(
      csharp,
      contains(
        'DefaultValue = MappingConverters.DateTimeToString(source.Value)',
      ),
    );
    expect(
      csharp,
      contains(
        'ImplicitValue = MappingConverters.DateTimeToString2(source.Value)',
      ),
    );
  });

  test(
    'uses the last converter for a type pair by default and named converters explicitly',
    () {
      final resolved = ResolvedSchema(
        parseMappingYaml('''
models:
  A:
    fields:
      value: int
  B:
    fields:
      value: String
      explicitValue: String
converters:
  - name: firstIntToString
    from: int
    to: String
    dart:
      expression: "'first'"
    csharp:
      expression: '"first"'
  - name: secondIntToString
    from: int
    to: String
    dart:
      expression: "'second'"
    csharp:
      expression: '"second"'
mappings:
  - from: A
    to: B
    fields:
      value: { from: value }
      explicitValue: { from: value, converter: firstIntToString }
'''),
      );
      resolved.validate();

      final dart = emitDart(resolved);
      expect(
        resolved.converterFor(parseType('int'), parseType('String'))!.name,
        'secondIntToString',
      );
      expect(dart, contains('static String secondIntToString(int source)'));
      expect(
        dart,
        contains('value: MappingConverters.secondIntToString(source.value)'),
      );
      expect(
        dart,
        contains(
          'explicitValue: MappingConverters.firstIntToString(source.value)',
        ),
      );
    },
  );

  test('allows explicit converters from nullable source to non-null target', () {
    final resolved = ResolvedSchema(
      parseMappingYaml('''
models:
  A:
    fields:
      value: String?
  B:
    fields:
      value: bool
converters:
  - name: nullableStringToBool
    from: String?
    to: bool
    dart:
      expression: source != null
    csharp:
      expression: source != null
mappings:
  - from: A
    to: B
    fields:
      value: { from: value, converter: nullableStringToBool }
'''),
    );
    resolved.validate();

    final dart = emitDart(resolved);
    expect(dart, contains('static bool nullableStringToBool(String? source)'));
    expect(
      dart,
      contains('value: MappingConverters.nullableStringToBool(source.value)'),
    );

    final csharp = emitCSharp(resolved);
    expect(
      csharp,
      contains('public static bool NullableStringToBool(string? source)'),
    );
    expect(
      csharp,
      contains('Value = MappingConverters.NullableStringToBool(source.Value)'),
    );
  });

  test('writes requested output file names', () {
    final temp = Directory.systemTemp.createTempSync('most_mapper_test_');
    try {
      final mapping = File(p.join(temp.path, 'mapping.yaml'))
        ..writeAsStringSync(_sampleYaml);
      final result = generate(
        GeneratorOptions(
          mappingPath: mapping.path,
          dartOutDir: p.join(temp.path, 'dart') + p.separator,
          dartFileName: 'custom.dart',
          csharpOutDir: p.join(temp.path, 'csharp') + p.separator,
          csharpFileName: 'Custom.cs',
        ),
      );

      expect(result.writtenFiles, hasLength(2));
      expect(
        File(p.join(temp.path, 'dart', 'custom.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(temp.path, 'csharp', 'Custom.cs')).existsSync(),
        isTrue,
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  });

  test('accepts paths with non-native separators', () {
    final temp = Directory.systemTemp.createTempSync('most_mapper_test_');
    try {
      final mappingPath = p.join(temp.path, 'mapping.yaml');
      File(mappingPath).writeAsStringSync(_sampleYaml);

      final result = generate(
        GeneratorOptions(
          mappingPath: _withNonNativeSeparators(mappingPath),
          dartOutDir: _withNonNativeSeparators(p.join(temp.path, 'dart')),
          dartFileName: 'custom.dart',
          csharpOutDir: _withNonNativeSeparators(p.join(temp.path, 'csharp')),
          csharpFileName: 'Custom.cs',
        ),
      );

      expect(result.writtenFiles, hasLength(2));
      expect(
        File(p.join(temp.path, 'dart', 'custom.dart')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(temp.path, 'csharp', 'Custom.cs')).existsSync(),
        isTrue,
      );
    } finally {
      temp.deleteSync(recursive: true);
    }
  });
}

String _withNonNativeSeparators(String path) {
  return Platform.isWindows
      ? path.replaceAll(r'\', '/')
      : path.replaceAll('/', r'\');
}

ResolvedSchema _resolvedSample() {
  final resolved = ResolvedSchema(parseMappingYaml(_sampleYaml));
  resolved.validate();
  return resolved;
}

const _sampleYaml = r'''
models:
  Measurement:
    doc: Sample scaled numeric value.
    json: true
    fields:
      code: String
      scale: int
      value: int

  OrderStatus:
    enum:
      pending: { string: pending, int: 0 }
      captured: { string: captured, int: 1 }
      failed: { string: failed, int: 2 }

  ModelA:
    doc: Domain model.
    json: true
    fields:
      JsonFieldName: { type: String, nullable: true }
      reading: Measurement
      status: OrderStatus
      bs: List<ModelB>
      createdAt: DateTime?

  ModelAWire:
    doc: Wire model.
    json: true
    fields:
      Id: String?
      reading: decimal
      status: String
      statusCode: int
      bs: List<ModelBWire>
      createdAt: String?
      SomeField: String?

  ModelB:
    doc: Domain child model.
    json: true
    fields:
      Id: String
      Datetime: DateTime

  ModelBWire:
    doc: Wire child model.
    json: true
    fields:
      Id: String
      Datetime: String

converters:
  - from: Measurement
    to: decimal
    dart:
      imports: ["dart:math"]
      expression: "source.value / pow(10, source.scale)"
    csharp:
      usings: ["System"]
      expression: "(decimal)source.Value / (decimal)Math.Pow(10, source.Scale)"

  - name: offsetDateTimeToString
    from: DateTime
    to: String
    dart:
      expression: |
        (() {
          String two(int value) => value.toString().padLeft(2, '0');
          final offset = source.timeZoneOffset;
          final sign = offset.isNegative ? '-' : '+';
          final absoluteOffset = offset.abs();
          return '${source.year.toString().padLeft(4, '0')}-${two(source.month)}-${two(source.day)}T'
              '${two(source.hour)}:${two(source.minute)}:${two(source.second)}$sign'
              '${two(absoluteOffset.inHours)}:${two(absoluteOffset.inMinutes.remainder(60))}';
        })()
    csharp:
      usings: ["System", "System.Globalization"]
      expression: |
        new DateTimeOffset(source).ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture)

  - name: offsetStringToDateTime
    from: String
    to: DateTime
    dart:
      expression: |
        (() {
          final match = RegExp(r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})([+-])(\d{2}):(\d{2})$').firstMatch(source);
          if (match == null) {
            throw FormatException('Expected yyyy-MM-ddTHH:mm:ss+XX:XX', source);
          }
          final withoutOffsetUtc = DateTime.parse('${match.group(1)}Z');
          final offset = Duration(
            hours: int.parse(match.group(3)!),
            minutes: int.parse(match.group(4)!),
          );
          return match.group(2) == '+'
              ? withoutOffsetUtc.subtract(offset)
              : withoutOffsetUtc.add(offset);
        })()
    csharp:
      usings: ["System", "System.Globalization"]
      expression: |
        DateTimeOffset.ParseExact(
            source,
            "yyyy-MM-dd'T'HH:mm:sszzz",
            CultureInfo.InvariantCulture
        ).UtcDateTime

mappings:
  - from: ModelB
    to: ModelBWire
    fields:
      Datetime: { from: Datetime, converter: offsetDateTimeToString }

  - from: ModelBWire
    to: ModelB
    fields:
      Datetime: { from: Datetime, converter: offsetStringToDateTime }

  - from: ModelA
    to: ModelAWire
    fields:
      Id: { from: JsonFieldName }
      reading: { from: reading }
      status: { from: status }
      statusCode: { from: status }
      createdAt: { from: createdAt }
      SomeField: { const: null }
''';
