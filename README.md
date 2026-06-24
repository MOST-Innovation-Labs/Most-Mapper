# Most-Mapper

Most-Mapper is a small Dart CLI package that generates Dart and C# mapping code from a single YAML file.
The YAML file declares data models, enums, custom converter expressions, and typed mappings between models.
Generated Dart files are formatted with `dart format`. Generated C# files are formatted with `dotnet format`.

## Usage

Generate both Dart and C#:

```bash
dart run most_mapper \
  --mapping example/basic/mapping.yaml \
  --dart-out-dir example/basic/output/dart \
  --dart-file-name models_mapper.g.dart \
  --csharp-out-dir example/basic/output/csharp \
  --csharp-file-name ModelsMapper.g.cs
```

Generate Dart only:

```bash
dart run most_mapper --mapping mapping.yaml --dart-out-dir output/dart
```

Generate C# only:

```bash
dart run most_mapper --mapping mapping.yaml --csharp-out-dir output/csharp
```

Defaults:

| CLI option | Default |
|---|---|
| `--dart-file-name` | `most_mapper.g.dart` |
| `--csharp-file-name` | `MostMapper.g.cs` |

`--mapping` is required. At least one of `--dart-out-dir` or `--csharp-out-dir` must be present.
C# generation requires the .NET SDK because the generated `.cs` file is passed through `dotnet format`.

## YAML Features

- `models` declares generated data classes and enums.
- `json: true` on a data model generates JSON helpers. It defaults to `false`.
- Fields support `field: Type`, `field: Type?`, and `{ type: Type, nullable: true, doc: Description }`.
- Enum models support string and int wire values.
- Enums can map to and from `String` and `int` when every enum value declares that wire value.
- `converters` define trusted raw Dart and C# expressions emitted as private helper methods.
- Converter `name` is optional. Use a name only when a mapping must select a specific non-default converter.
- Field mappings can use `{ from: SourceField, converter: converterName }` to force a named converter, or
  `{ from: SourceField, converter: default }` to force a built-in default converter when available.
- `DateTime` has default `DateTime -> String` and `String -> DateTime` converters using UTC ISO text like
  `2026-06-24T07:19:06Z`.
- Multiline converter expressions are supported with YAML block strings.
- `mappings` generate typed extension methods on source models.
- Mapping fields support `{ from: SourceField }`, `{ const: null }`, and scalar constants.
- Mapping field names are case-sensitive YAML keys.

## Data Types

| YAML type | Dart type | C# type | Notes |
|---|---|---|---|
| `String` | `String` | `string` | Basic scalar |
| `bool` | `bool` | `bool` | Basic scalar |
| `int` | `int` | `int` | Numeric cast source/target |
| `double` | `double` | `double` | Numeric cast source/target |
| `num` | `num` | `double` | Conservative numeric support |
| `decimal` | `double` | `decimal` | Wire/business decimal support |
| `DateTime` | `DateTime` | `DateTime` | Default JSON text is UTC ISO, e.g. `2026-06-24T07:19:06Z` |
| `List<T>` | `List<T>` | `List<T>` | Element-wise mapping/conversion |
| custom model | generated class | generated class | Declared in `models` |
| enum model | generated enum | generated enum | Supports string/int scalar conversion |

## Mapping Rules

- Default mapping assigns target fields from source fields with the same YAML key when the value is compatible.
- Compatible means identical, numeric-castable, enum-scalar convertible, model-mappable, list-compatible, or converter-backed.
- Every target field must be assigned by default mapping or an explicit mapping entry.
- `const: null` is only valid for nullable target fields.
- Scalar constants are validated against the target field type.
- The generator fails before writing output if validation fails.

## Converter Expressions

Converters are raw code emitted into private helper methods in the generated file. Treat the mapping YAML as trusted
input.
Converter names are optional. If multiple converters have the same `from` and `to` types, the last converter in the
file is used by default; mappings can still reference any named converter explicitly. The name `default` is reserved.

Each converter has `from`, `to`, `dart.expression`, and `csharp.expression`; `name` is optional. The generated helper
method passes the input value as a parameter named `source`; expressions should return the converted value.

```yaml
converters:
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
          return '${source.year.toString().padLeft(4, '0')}-${two(source.month)}-${two(source.day)}T${two(source.hour)}:${two(source.minute)}:${two(source.second)}$sign${two(absoluteOffset.inHours)}:${two(absoluteOffset.inMinutes.remainder(60))}';
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
```

The example emits offset text like `2026-06-24T07:19:06+00:00`. When reading text back, the timestamp part is
treated as UTC, then `+HH:mm` offsets are subtracted and `-HH:mm` offsets are added so the returned `DateTime`
represents the same instant in UTC.

## Example Mapping YAML

```yaml
models:
  Money:
    doc: Monetary amount stored as minor units.
    json: true
    fields:
      code: String
      fractionalUnits: int
      value: int

  PaymentStatus:
    enum:
      pending: { string: pending, int: 0 }
      captured: { string: captured, int: 1 }
      failed: { string: failed, int: 2 }

  ModelA:
    doc: Domain model.
    json: true
    fields:
      JsonFieldName: { type: String, nullable: true }
      amount: Money
      status: PaymentStatus
      bs: List<ModelB>
      createdAt: DateTime?

  ModelAWire:
    doc: Wire model.
    json: true
    fields:
      Id: String?
      amount: decimal
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
  - from: Money
    to: decimal
    dart:
      imports: ["dart:math"]
      expression: "source.value / pow(10, source.fractionalUnits)"
    csharp:
      usings: ["System"]
      expression: "(decimal)source.Value / (decimal)Math.Pow(10, source.FractionalUnits)"

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
          return '${source.year.toString().padLeft(4, '0')}-${two(source.month)}-${two(source.day)}T${two(source.hour)}:${two(source.minute)}:${two(source.second)}$sign${two(absoluteOffset.inHours)}:${two(absoluteOffset.inMinutes.remainder(60))}';
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
      amount: { from: amount }
      status: { from: status }
      statusCode: { from: status }
      createdAt: { from: createdAt, converter: default }
      SomeField: { const: null }
```

## Validation Failures

The generator stops before writing output when it finds errors such as:

- Unknown models, fields, or types.
- Missing converters or mappings for incompatible fields.
- Duplicate enum wire values.
- Invalid constants.
- Unsafe nullable-to-non-nullable assignments.
- Generated Dart or C# identifier collisions.

## Assumptions

- One YAML file is the v1 source of truth. There are no separate `--spec` files.
- `models` is the only type declaration section. Enums are declared inside `models`.
- YAML scalar constants only are supported for `{ const: ... }` in v1.
- Raw converter expressions are emitted into generated private helper methods and are not sandboxed.
- The built-in DateTime converters use UTC ISO text ending in `Z`; custom DateTime converters can override that format.
- Mapping field names are case-sensitive YAML keys.
- Output is one generated file per requested target language.
- Generated Dart and C# files are formatted before the CLI exits.

## Development

```bash
dart test
dart analyze
dart format --set-exit-if-changed --line-length 120 .
```
