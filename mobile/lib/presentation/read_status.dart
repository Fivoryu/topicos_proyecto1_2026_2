import '../data/repositories/repository_support.dart';

/// Lifecycle of a protected REST read.
enum ReadStatus { loading, loaded, empty, error, corruptionRecovery }

bool isCorruptionFailure(Object error) =>
    error is ReadRepositoryException && error.isCorruption ||
    error is FormatException;

String readFailureMessage(Object error, String resource) {
  if (error is ReadRepositoryException) return error.message;
  return 'Unable to load $resource. ${error.toString()}';
}

String recoveryMessage(String resource) =>
    'Unable to load $resource because the saved data is corrupted. '
    'Please recover the server data before trying again.';
