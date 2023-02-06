# Example

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
