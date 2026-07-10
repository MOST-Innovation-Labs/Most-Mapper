# Changelog

## 0.3.0

- Added closed tagged unions with Dart sealed variants and C# abstract/sealed variants.
- Added discriminator-based JSON serialization that rejects unknown union tags.

## 0.2.2

- Allowed explicitly named converters to map nullable source fields to non-nullable targets when the converter
  signature exactly matches the nullable source type.

## 0.2.1

- Renamed generated mapping parameters when they would shadow internal mapper locals.
- Kept generated source model locals stable while suffixing conflicting parameters with `Param`.

## 0.2.0

- Added mapping field parameters with `{ parameter: Type }`, generating required mapping function parameters.
- Added Dart and C# conversion support for parameter values using existing mapper conversion rules.
- Added parameter mapping coverage to the basic example.

## 0.1.0

- Initial release with YAML parsing, schema validation, and Dart/C# mapper generation.
- Added generated model, enum, JSON, converter, and mapping extension support.
