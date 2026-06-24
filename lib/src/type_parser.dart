import 'schema.dart';

TypeRef parseType(String source) {
  var text = source.trim();
  if (text.isEmpty) {
    throw MapperException('Type cannot be empty.');
  }

  var nullable = false;
  if (text.endsWith('?')) {
    nullable = true;
    text = text.substring(0, text.length - 1).trim();
  }

  if (text.startsWith('List<') && text.endsWith('>')) {
    final inner = text.substring(5, text.length - 1);
    return TypeRef(name: 'List', nullable: nullable, item: parseType(inner));
  }

  return TypeRef(name: text, nullable: nullable);
}
