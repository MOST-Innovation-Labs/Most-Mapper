import 'dart:io';

import 'package:args/args.dart';
import 'package:most_mapper/most_mapper.dart';

void main(List<String> arguments) {
  final parser = _argParser();
  try {
    final results = parser.parse(arguments);
    if (results['help'] as bool) {
      stdout.writeln(_usage(parser));
      return;
    }

    final result = generate(
      GeneratorOptions(
        mappingPath: _requiredOption(results, 'mapping'),
        dartOutDir: results['dart-out-dir'] as String?,
        dartFileName: (results['dart-file-name'] as String?) ?? defaultDartFileName,
        csharpOutDir: results['csharp-out-dir'] as String?,
        csharpFileName: (results['csharp-file-name'] as String?) ?? defaultCSharpFileName,
      ),
    );

    for (final path in result.writtenFiles) {
      stdout.writeln('Generated $path');
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln();
    stderr.writeln(_usage(parser));
    exitCode = 64;
  } on MapperException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

ArgParser _argParser() {
  return ArgParser()
    ..addOption('mapping', help: 'Path to the mapping YAML file.')
    ..addOption('dart-out-dir', help: 'Directory for generated Dart output.')
    ..addOption('dart-file-name', help: 'Generated Dart file name.', defaultsTo: defaultDartFileName)
    ..addOption('csharp-out-dir', help: 'Directory for generated C# output.')
    ..addOption('csharp-file-name', help: 'Generated C# file name.', defaultsTo: defaultCSharpFileName)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');
}

String _requiredOption(ArgResults results, String name) {
  final value = results[name] as String?;
  if (value == null || value.trim().isEmpty) {
    throw MapperException('--$name is required.');
  }
  return value;
}

String _usage(ArgParser parser) {
  return 'Usage: dart run most_mapper --mapping mapping.yaml [outputs]\n\n${parser.usage}';
}
