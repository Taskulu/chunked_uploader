library chunked_uploader;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class ChunkedUploader {
  final Dio _dio;
  final File _file;
  final String _fileName, _path, _method, _fileKey;
  final Map<String, dynamic> _data;
  int _fileSize;
  int _maxChunkSize;

  ChunkedUploader({
    BaseOptions options,
    String path,
    String filePath,
    Map<String, dynamic> data,
    int maxChunkSize = 0,
    String fileKey = 'file',
    String method = 'POST',
  })  : assert(options != null || path != null),
        assert(method != null),
        assert(fileKey != null),
        assert(filePath != null),
        assert(maxChunkSize > 0),
        this._dio = Dio(options),
        this._file = File(filePath),
        this._fileName = p.basename(filePath),
        this._path = path,
        this._fileKey = fileKey,
        this._method = method,
        this._data = data {
    this._fileSize = this._file.lengthSync();
    this._maxChunkSize = min(maxChunkSize, _fileSize);
  }

  final StreamController<double> _uploadProgressController = StreamController();
  final CancelToken _cancelToken = CancelToken();

  Future<Response> upload() async {
    Response finalResponse;
    for (int i = 0; i < _chunksCount; i++) {
      final start = _getChunkStart(i);
      final end = _getChunkEnd(i);
      final chunkStream = _getChunkStream(start, end);
      final formData = FormData.fromMap({
        _fileKey: MultipartFile(chunkStream, end - start, filename: _fileName),
        if (_data != null) ..._data
      });
      finalResponse = await _dio.request(
        _path,
        data: formData,
        cancelToken: _cancelToken,
        options: Options(
          method: _method,
          headers: _getHeaders(start, end),
        ),
        onSendProgress: (current, total) => _updateProgress(i, current, total),
      );
    }
    _uploadProgressController.close();
    return finalResponse;
  }

  cancel([String message]) {
    _cancelToken.cancel(message);
    _uploadProgressController.close();
  }

  // Updating total upload progress
  _updateProgress(int chunkIndex, int chunkCurrent, int chunkTotal) {
    int totalUploadedSize = (chunkIndex * _maxChunkSize) + chunkCurrent;
    double totalUploadProgress = totalUploadedSize / _fileSize;
    _uploadProgressController.add(totalUploadProgress);
  }

  Stream<List<int>> _getChunkStream(int start, int end) =>
      _file.openRead(start, end);

  // Returning start byte offset of current chunk
  int _getChunkStart(int chunkIndex) => chunkIndex * _maxChunkSize;

  // Returning end byte offset of current chunk
  int _getChunkEnd(int chunkIndex) =>
      min((chunkIndex + 1) * _maxChunkSize, _fileSize);

  // Returning a header map object containing Content-Range
  // https://tools.ietf.org/html/rfc7233#section-2
  Map<String, dynamic> _getHeaders(int start, int end) =>
      {'Content-Range': 'bytes $start-${end - 1}/$_fileSize'};

  // Returning chunks count based on file size and maximum chunk size
  int get _chunksCount => (_fileSize / _maxChunkSize).ceil();

  Stream<double> get progressStream => _uploadProgressController.stream;
}
