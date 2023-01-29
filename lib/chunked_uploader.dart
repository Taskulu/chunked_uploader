library chunked_uploader;

import 'dart:async';
import 'dart:math';
import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';

class ChunkedUploader {
  final Dio _dio;

  const ChunkedUploader(this._dio);

  Future<Response?> upload({
    required Stream<List<int>> fileDataStream,
    required String fileName,
    required int fileSize,
    required String path,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    int? maxChunkSize,
    Function(double)? onUploadProgress,
    String method = 'POST',
    String fileKey = 'file',
  }) =>
      UploadRequest(
        _dio,
        fileDataStream: fileDataStream,
        fileName: fileName,
        fileSize: fileSize,
        path: path,
        fileKey: fileKey,
        method: method,
        data: data,
        cancelToken: cancelToken,
        maxChunkSize: maxChunkSize,
        onUploadProgress: onUploadProgress,
      ).upload();

  Future<Response?> uploadWithFilePath({
    required String filePath,
    required String path,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    int? maxChunkSize,
    Function(double)? onUploadProgress,
    String method = 'POST',
    String fileKey = 'file',
  }) =>
      UploadRequest.fromFilePath(
        _dio,
        filePath: filePath,
        path: path,
        fileKey: fileKey,
        method: method,
        data: data,
        cancelToken: cancelToken,
        maxChunkSize: maxChunkSize,
        onUploadProgress: onUploadProgress,
      ).upload();
}

class UploadRequest {
  final Dio dio;
  late final int fileSize;
  late final ChunkedStreamReader<int> streamReader;
  final String fileName, path, fileKey;
  final String? method;
  final Map<String, dynamic>? data;
  final CancelToken? cancelToken;
  final Function(double)? onUploadProgress;
  late int _maxChunkSize;

  UploadRequest(
    this.dio, {
    required Stream<List<int>> fileDataStream,
    required this.fileName,
    required this.fileSize,
    required this.path,
    required this.fileKey,
    this.method,
    this.data,
    this.cancelToken,
    this.onUploadProgress,
    int? maxChunkSize,
  }) : streamReader = ChunkedStreamReader(fileDataStream) {
    _maxChunkSize = min(fileSize, maxChunkSize ?? fileSize);
  }

  UploadRequest.fromFilePath(
    this.dio, {
    required String filePath,
    required this.path,
    required this.fileKey,
    this.method,
    this.data,
    this.cancelToken,
    this.onUploadProgress,
    int? maxChunkSize,
  }) : fileName = p.basename(filePath) {
    final file = File(filePath);
    streamReader = ChunkedStreamReader(file.openRead());
    fileSize = file.lengthSync();
    _maxChunkSize = min(fileSize, maxChunkSize ?? fileSize);
  }

  Future<Response?> upload() async {
    Response? finalResponse;
    for (int i = 0; i < _chunksCount; i++) {
      final start = _getChunkStart(i);
      final end = _getChunkEnd(i);
      final chunkStream = _getChunkStream();
      final formData = FormData.fromMap({
        fileKey: MultipartFile(chunkStream, end - start, filename: fileName),
        if (data != null) ...data!
      });
      finalResponse = await dio.request(
        path,
        data: formData,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: _getHeaders(start, end),
        ),
        onSendProgress: (current, total) => _updateProgress(i, current, total),
      );
    }
    return finalResponse;
  }

  Stream<List<int>> _getChunkStream() => streamReader.readStream(_maxChunkSize);

  // Updating total upload progress
  void _updateProgress(int chunkIndex, int chunkCurrent, int chunkTotal) {
    int totalUploadedSize = (chunkIndex * _maxChunkSize) + chunkCurrent;
    double totalUploadProgress = totalUploadedSize / fileSize;
    this.onUploadProgress?.call(totalUploadProgress);
  }

  // Returning start byte offset of current chunk
  int _getChunkStart(int chunkIndex) => chunkIndex * _maxChunkSize;

  // Returning end byte offset of current chunk
  int _getChunkEnd(int chunkIndex) =>
      min((chunkIndex + 1) * _maxChunkSize, fileSize);

  // Returning a header map object containing Content-Range
  // https://tools.ietf.org/html/rfc7233#section-2
  Map<String, dynamic> _getHeaders(int start, int end) =>
      {'Content-Range': 'bytes $start-${end - 1}/$fileSize'};

  // Returning chunks count based on file size and maximum chunk size
  int get _chunksCount => (fileSize / _maxChunkSize).ceil();
}
