import 'package:dio/dio.dart';

import '../data/repositories/repository_support.dart';

/// Lifecycle of a protected REST read.
enum ReadStatus { loading, loaded, empty, error, corruptionRecovery }

bool isCorruptionFailure(Object error) =>
    error is ReadRepositoryException && error.isCorruption ||
    error is FormatException;

String readFailureMessage(Object error, String resource) {
  if (error is ReadRepositoryException) return error.message;
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => 'Your session expired. Please sign in again.',
      403 => 'You are not authorized to view $resource.',
      _ => 'Unable to load $resource. ${error.toString()}',
    };
  }
  return 'Unable to load $resource. ${error.toString()}';
}

String recoveryMessage(String resource) =>
    'Unable to load $resource because the saved data is corrupted. '
    'Please recover the server data before trying again.';
