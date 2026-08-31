import 'package:dio/dio.dart';

/// Failure returned when a protected read cannot produce a trustworthy model.
class ReadRepositoryException implements Exception {
  const ReadRepositoryException(this.message, {this.isCorruption = false});

  final String message;
  final bool isCorruption;

  @override
  String toString() => message;
}

T requireReadData<T>(Response<T> response, String resource) {
  final data = response.data;
  if (data == null) {
    throw ReadRepositoryException(
      'The server returned incomplete $resource data.',
      isCorruption: true,
    );
  }
  return data;
}

ReadRepositoryException corruptionFailure(Object error, String resource) {
  final detail = error is FormatException ? error.message : 'invalid response';
  return ReadRepositoryException(
    'The server returned corrupted $resource data: $detail',
    isCorruption: true,
  );
}
