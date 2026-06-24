import 'dart:io';

import 'csharp_emitter.dart';
import 'dart_emitter.dart';
import 'parser.dart';
import 'resolver.dart';
import 'schema.dart';

const defaultDartFileName = 'most_mapper.g.dart';
const defaultCSharpFileName = 'MostMapper.g.cs';

class GeneratorOptions {
  GeneratorOptions({
    required this.mappingPath,
    required this.dartOutDir,
    required this.dartFileName,
    required this.csharpOutDir,
    required this.csharpFileName,
  });

  final String mappingPath;
  final String? dartOutDir;
  final String dartFileName;
  final String? csharpOutDir;
  final String csharpFileName;
}

class GenerationResult {
  GenerationResult(this.writtenFiles);

  final List<String> writtenFiles;
}

GenerationResult generate(GeneratorOptions options) {
  _validateOptions(options);

  final mappingFile = File(options.mappingPath);
  if (!mappingFile.existsSync()) {
    throw MapperException('Mapping file does not exist: ${options.mappingPath}');
  }

  final schema = parseMappingYaml(mappingFile.readAsStringSync(), sourceName: options.mappingPath);
  final resolved = ResolvedSchema(schema);
  resolved.validate();

  final outputs = <_OutputFile>[];
  if (options.dartOutDir != null) {
    outputs.add(_OutputFile(options.dartOutDir!, options.dartFileName, emitDart(resolved)));
  }
  if (options.csharpOutDir != null) {
    outputs.add(_OutputFile(options.csharpOutDir!, options.csharpFileName, emitCSharp(resolved)));
  }

  final paths = <String>{};
  for (final output in outputs) {
    final path = output.path;
    if (!paths.add(path)) {
      throw MapperException('Dart and C# outputs resolve to the same file: $path');
    }
  }

  final written = <String>[];
  for (final output in outputs) {
    Directory(output.directory).createSync(recursive: true);
    File(output.path).writeAsStringSync(output.contents);
    output.format();
    output.validate();
    written.add(output.path);
  }
  return GenerationResult(written);
}

void _validateOptions(GeneratorOptions options) {
  if (options.mappingPath.trim().isEmpty) {
    throw MapperException('--mapping is required.');
  }
  if (options.dartOutDir == null && options.csharpOutDir == null) {
    throw MapperException('At least one of --dart-out-dir or --csharp-out-dir is required.');
  }
  _validateFileName(options.dartFileName, '--dart-file-name');
  _validateFileName(options.csharpFileName, '--csharp-file-name');
}

void _validateFileName(String fileName, String optionName) {
  if (fileName.trim().isEmpty || fileName.contains('/') || fileName.contains(r'\')) {
    throw MapperException('$optionName must be a file name, not a path.');
  }
}

class _OutputFile {
  _OutputFile(this.directory, this.fileName, this.contents);

  final String directory;
  final String fileName;
  final String contents;

  String get path => '${directory.endsWith('/') ? directory.substring(0, directory.length - 1) : directory}/$fileName';

  void format() {
    if (fileName.endsWith('.dart')) {
      _runFormatter('dart', ['format', '--line-length', '120', path]);
      return;
    }
    if (fileName.endsWith('.cs')) {
      _formatCSharp(path);
    }
  }

  void validate() {
    if (fileName.endsWith('.dart')) {
      _runValidator('dart', ['analyze', path]);
      return;
    }
    if (fileName.endsWith('.cs')) {
      _validateCSharp(path);
    }
  }
}

void _formatCSharp(String path) {
  final tempDir = Directory.systemTemp.createTempSync('most_mapper_dotnet_format_');
  try {
    final project = File('${tempDir.path}/MostMapperFormat.csproj');
    project.writeAsStringSync('''
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="${_xmlEscape(File(path).absolute.path)}" />
  </ItemGroup>
</Project>
''');
    _runFormatter('dotnet', [
      'format',
      'whitespace',
      project.path,
      '--include',
      File(path).absolute.path,
      '--include-generated',
      '--no-restore',
      '-v',
      'quiet',
    ]);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void _validateCSharp(String path) {
  final tempDir = Directory.systemTemp.createTempSync('most_mapper_dotnet_validate_');
  try {
    final project = File('${tempDir.path}/MostMapperValidate.csproj');
    project.writeAsStringSync('''
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0</TargetFramework>
    <Nullable>enable</Nullable>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <ImplicitUsings>disable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="${_xmlEscape(File(path).absolute.path)}" />
  </ItemGroup>
</Project>
''');
    _runValidator('dotnet', ['build', project.path, '--nologo', '-v', 'quiet']);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void _runFormatter(String executable, List<String> arguments) {
  _runCommand(executable, arguments, 'formatter');
}

void _runValidator(String executable, List<String> arguments) {
  _runCommand(executable, arguments, 'validation');
}

void _runCommand(String executable, List<String> arguments, String action) {
  final result = Process.runSync(executable, arguments);
  if (result.exitCode == 0) {
    return;
  }

  final output = [result.stdout, result.stderr].where((value) => value.toString().trim().isNotEmpty).join('\n');
  throw MapperException('$executable $action failed with exit code ${result.exitCode}.\n$output');
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
