# Chunked Uploader

A plugin to upload files to server in chunks.

![pub package](https://img.shields.io/pub/v/chunked_uploader.svg)

## Usage

To use this plugin, add chunked_uploader as dependency in your pubspec.yaml file.

``` yaml
dependencies:
  flutter:
    sdk: flutter
  chunked_uploader: ^0.0.1
```

## Example

``` dart
ChunkedUploader chunkedUploader = ChunkedUploader(Dio(BaseOptions(
    baseUrl: 'https://example.com/api',
    headers: {'Authorization': 'Bearer'})));
try {
  Response response = await chunkedUploader.upload(
      filePath: '/path/to/file',
      maxChunkSize: 500000,
      path: '/file',
      onUploadProgress: (progress) => print(progress));
  print(response);
} on DioError catch (e) {
  print(e);
}
```