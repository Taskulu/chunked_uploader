# Chunked Uploader

A plugin to upload files to server in chunks.

![pub package](https://img.shields.io/pub/v/chunked_uploader.svg)

## Usage

To use this plugin, add chunked_uploader as dependency in your pubspec.yaml file.

``` yaml
dependencies:
  flutter:
    sdk: flutter
  chunked_uploader: ^1.0.0
  file_picker: ^5.2.5
  dio: ^4.0.6
```

## Example

``` dart
final file =
    (await FilePicker.platform.pickFiles(withReadStream: true))!.files.single;
final dio = Dio(BaseOptions(
  baseUrl: 'https://example.com/api',
  headers: {'Authorization': 'Bearer'},
));
final uploader = ChunkedUploader(dio);

// using data stream
final response = await uploader.upload(
  fileName: file.name,
  fileSize: file.size,
  fileDataStream: file.readStream!,
  maxChunkSize: 500000,
  path: '/file',
  onUploadProgress: (progress) => print(progress),
);
// using path
final response = await uploader.uploadUsingFilePath(
  fileName: file.name,
  filePath: file.path!,
  maxChunkSize: 500000,
  path: '/file',
  onUploadProgress: (progress) => print(progress),
);
```
