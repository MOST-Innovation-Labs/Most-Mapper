String dartStringLiteral(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n');
  return "'$escaped'";
}

String csharpStringLiteral(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
  return '"$escaped"';
}

String lowerFirst(String value) => value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);
