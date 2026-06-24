// GENERATED CODE - DO NOT MODIFY BY HAND.
// ignore_for_file: unnecessary_parenthesis, unused_element, avoid-high-cyclomatic-complexity

import 'dart:math';

class MostMapperConverters {
  const MostMapperConverters._();

  static String dateTimeToString(DateTime source) {
    return (source.toUtc().toIso8601String());
  }

  static double moneyToDecimal(Money source) {
    return (source.value / pow(10, source.fractionalUnits));
  }

  static String offsetDateTimeToString(DateTime source) {
    return ((() {
      String two(int value) => value.toString().padLeft(2, '0');
      final offset = source.timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final absoluteOffset = offset.abs();
      return '${source.year.toString().padLeft(4, '0')}-${two(source.month)}-${two(source.day)}T${two(source.hour)}:${two(source.minute)}:${two(source.second)}$sign${two(absoluteOffset.inHours)}:${two(absoluteOffset.inMinutes.remainder(60))}';
    })());
  }

  static DateTime offsetStringToDateTime(String source) {
    return ((() {
      final match = RegExp(r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})([+-])(\d{2}):(\d{2})$').firstMatch(source);
      if (match == null) {
        throw FormatException('Expected yyyy-MM-ddTHH:mm:ss+XX:XX', source);
      }
      final withoutOffsetUtc = DateTime.parse('${match.group(1)}Z');
      final offset = Duration(hours: int.parse(match.group(3)!), minutes: int.parse(match.group(4)!));
      return match.group(2) == '+' ? withoutOffsetUtc.subtract(offset) : withoutOffsetUtc.add(offset);
    })());
  }
}

enum PaymentStatus { pending, captured, failed }

String paymentStatusToString(PaymentStatus value) {
  switch (value) {
    case PaymentStatus.pending:
      return 'pending';
    case PaymentStatus.captured:
      return 'captured';
    case PaymentStatus.failed:
      return 'failed';
  }
}

PaymentStatus paymentStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return PaymentStatus.pending;
    case 'captured':
      return PaymentStatus.captured;
    case 'failed':
      return PaymentStatus.failed;
    default:
      throw ArgumentError.value(value, 'value', 'Unknown PaymentStatus string');
  }
}

int paymentStatusToInt(PaymentStatus value) {
  switch (value) {
    case PaymentStatus.pending:
      return 0;
    case PaymentStatus.captured:
      return 1;
    case PaymentStatus.failed:
      return 2;
  }
}

PaymentStatus paymentStatusFromInt(int value) {
  switch (value) {
    case 0:
      return PaymentStatus.pending;
    case 1:
      return PaymentStatus.captured;
    case 2:
      return PaymentStatus.failed;
    default:
      throw ArgumentError.value(value, 'value', 'Unknown PaymentStatus int');
  }
}

/// Monetary amount stored as minor units.
class Money {
  const Money({required this.code, required this.fractionalUnits, required this.value});

  final String code;
  final int fractionalUnits;
  final int value;

  Map<String, dynamic> toJson() => <String, dynamic>{'code': code, 'fractionalUnits': fractionalUnits, 'value': value};

  factory Money.fromJson(Map<String, dynamic> json) =>
      Money(code: json['code'] as String, fractionalUnits: json['fractionalUnits'] as int, value: json['value'] as int);
}

/// Domain model.
class ModelA {
  const ModelA({
    required this.jsonFieldName,
    required this.amount,
    required this.status,
    required this.bs,
    required this.createdAt,
  });

  final String? jsonFieldName;
  final Money amount;
  final PaymentStatus status;
  final List<ModelB> bs;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'JsonFieldName': jsonFieldName == null ? null : jsonFieldName!,
    'amount': amount.toJson(),
    'status': paymentStatusToString(status),
    'bs': bs.map((item) => item.toJson()).toList(),
    'createdAt': createdAt == null ? null : MostMapperConverters.offsetDateTimeToString(createdAt!),
  };

  factory ModelA.fromJson(Map<String, dynamic> json) => ModelA(
    jsonFieldName: json['JsonFieldName'] == null ? null : json['JsonFieldName'] as String,
    amount: Money.fromJson(json['amount'] as Map<String, dynamic>),
    status: paymentStatusFromString(json['status'] as String),
    bs: (json['bs'] as List<dynamic>).map((item) => ModelB.fromJson(item as Map<String, dynamic>)).toList(),
    createdAt: json['createdAt'] == null
        ? null
        : MostMapperConverters.offsetStringToDateTime(json['createdAt'] as String),
  );
}

/// Wire model.
class ModelAWire {
  const ModelAWire({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusCode,
    required this.bs,
    required this.createdAt,
    required this.someField,
  });

  final String? id;
  final double amount;
  final String status;
  final int statusCode;
  final List<ModelBWire> bs;
  final String? createdAt;
  final String? someField;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'Id': id == null ? null : id!,
    'amount': amount,
    'status': status,
    'statusCode': statusCode,
    'bs': bs.map((item) => item.toJson()).toList(),
    'createdAt': createdAt == null ? null : createdAt!,
    'SomeField': someField == null ? null : someField!,
  };

  factory ModelAWire.fromJson(Map<String, dynamic> json) => ModelAWire(
    id: json['Id'] == null ? null : json['Id'] as String,
    amount: (json['amount'] as num).toDouble(),
    status: json['status'] as String,
    statusCode: json['statusCode'] as int,
    bs: (json['bs'] as List<dynamic>).map((item) => ModelBWire.fromJson(item as Map<String, dynamic>)).toList(),
    createdAt: json['createdAt'] == null ? null : json['createdAt'] as String,
    someField: json['SomeField'] == null ? null : json['SomeField'] as String,
  );
}

/// Domain child model.
class ModelB {
  const ModelB({required this.id, required this.datetime});

  final String id;
  final DateTime datetime;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'Id': id,
    'Datetime': MostMapperConverters.offsetDateTimeToString(datetime),
  };

  factory ModelB.fromJson(Map<String, dynamic> json) => ModelB(
    id: json['Id'] as String,
    datetime: MostMapperConverters.offsetStringToDateTime(json['Datetime'] as String),
  );
}

/// Wire child model.
class ModelBWire {
  const ModelBWire({required this.id, required this.datetime});

  final String id;
  final String datetime;

  Map<String, dynamic> toJson() => <String, dynamic>{'Id': id, 'Datetime': datetime};

  factory ModelBWire.fromJson(Map<String, dynamic> json) =>
      ModelBWire(id: json['Id'] as String, datetime: json['Datetime'] as String);
}

extension ModelBToModelBWire on ModelB {
  ModelBWire toModelBWire() {
    final source = this;
    return ModelBWire(id: source.id, datetime: MostMapperConverters.offsetDateTimeToString(source.datetime));
  }
}

extension ModelBWireToModelB on ModelBWire {
  ModelB toModelB() {
    final source = this;
    return ModelB(id: source.id, datetime: MostMapperConverters.offsetStringToDateTime(source.datetime));
  }
}

extension ModelAToModelAWire on ModelA {
  ModelAWire toModelAWire() {
    final source = this;
    return ModelAWire(
      id: source.jsonFieldName,
      amount: MostMapperConverters.moneyToDecimal(source.amount),
      status: paymentStatusToString(source.status),
      statusCode: paymentStatusToInt(source.status),
      bs: source.bs.map((item) => item.toModelBWire()).toList(),
      createdAt: source.createdAt == null ? null : MostMapperConverters.dateTimeToString(source.createdAt!),
      someField: null,
    );
  }
}
