import 'package:recase/recase.dart';

import 'schema.dart';

const _dartKeywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

String dartTypeName(String raw) => _validIdentifier(ReCase(raw).pascalCase, fallback: 'GeneratedType');

String dartFieldName(String raw) {
  final identifier = _validIdentifier(ReCase(raw).camelCase, fallback: 'field');
  return _dartKeywords.contains(identifier) ? '${identifier}_' : identifier;
}

String dartEnumValueName(String raw) => dartFieldName(raw);

String dartConverterBaseMethodName(ConverterDef converter) {
  final identifier = dartFieldName(_converterRawName(converter));
  return identifier.startsWith('_') ? 'converter${identifier.substring(1)}' : identifier;
}

Map<ConverterDef, String> dartConverterMethodNames(Iterable<ConverterDef> converters) {
  return _converterMethodNames(converters, dartConverterBaseMethodName);
}

String csharpTypeName(String raw) => _validIdentifier(ReCase(raw).pascalCase, fallback: 'GeneratedType');

String csharpPropertyName(String raw) => _validIdentifier(ReCase(raw).pascalCase, fallback: 'Property');

String csharpEnumValueName(String raw) => csharpPropertyName(raw);

String csharpConverterBaseMethodName(ConverterDef converter) => csharpTypeName(_converterRawName(converter));

Map<ConverterDef, String> csharpConverterMethodNames(Iterable<ConverterDef> converters) {
  return _converterMethodNames(converters, csharpConverterBaseMethodName);
}

String _converterRawName(ConverterDef converter) {
  return converter.name ?? '${_converterTypeName(converter.from)}To${_converterTypeName(converter.to)}';
}

String _converterTypeName(TypeRef type) {
  if (type.isList) {
    return 'List${_converterTypeName(type.item!)}';
  }
  return csharpTypeName(type.name);
}

Map<ConverterDef, String> _converterMethodNames(
  Iterable<ConverterDef> converters,
  String Function(ConverterDef converter) baseName,
) {
  final names = <ConverterDef, String>{};
  final counts = <String, int>{};
  for (final converter in converters) {
    final base = baseName(converter);
    final ordinal = (counts[base] ?? 0) + 1;
    counts[base] = ordinal;
    names[converter] = ordinal == 1 ? base : '$base$ordinal';
  }
  return names;
}

String _validIdentifier(String value, {required String fallback}) {
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    final char = value[index];
    final valid = RegExp(r'[A-Za-z0-9_]').hasMatch(char);
    if (valid) {
      buffer.write(char);
    }
  }

  var identifier = buffer.toString();
  if (identifier.isEmpty) {
    identifier = fallback;
  }
  if (RegExp(r'^[0-9]').hasMatch(identifier)) {
    identifier = '_$identifier';
  }
  return identifier;
}
