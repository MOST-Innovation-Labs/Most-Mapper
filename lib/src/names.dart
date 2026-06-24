import 'package:recase/recase.dart';

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

String dartConverterMethodName(String? raw, int index) =>
    raw == null ? '_mostMapperConverter$index' : '_${dartFieldName(raw)}';

String csharpTypeName(String raw) => _validIdentifier(ReCase(raw).pascalCase, fallback: 'GeneratedType');

String csharpPropertyName(String raw) => _validIdentifier(ReCase(raw).pascalCase, fallback: 'Property');

String csharpEnumValueName(String raw) => csharpPropertyName(raw);

String csharpConverterMethodName(String? raw, int index) =>
    raw == null ? 'MostMapperConvert$index' : 'MostMapperConvert${csharpTypeName(raw)}';

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
