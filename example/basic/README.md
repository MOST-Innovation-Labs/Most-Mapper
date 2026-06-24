# Most-Mapper Basic Example

Generate Dart and C# outputs from the example mapping:

```bash
dart run most_mapper \
  --mapping mapping.yaml \
  --dart-out-dir output/dart \
  --dart-file-name models_mapper.g.dart \
  --csharp-out-dir output/csharp \
  --csharp-file-name ModelsMapper.g.cs
```

Generated files are written under `output/`.
