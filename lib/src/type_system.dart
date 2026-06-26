import 'schema.dart';

const scalarTypeNames = {
  'String',
  'bool',
  'int',
  'long',
  'double',
  'num',
  'decimal',
  'DateTime',
};
const numericTypeNames = {'int', 'long', 'double', 'num', 'decimal'};

const stringType = TypeRef(name: 'String', nullable: false);
const dateTimeType = TypeRef(name: 'DateTime', nullable: false);

bool isScalarTypeName(String name) => scalarTypeNames.contains(name);

bool isNumericType(TypeRef type) => numericTypeNames.contains(type.name);
