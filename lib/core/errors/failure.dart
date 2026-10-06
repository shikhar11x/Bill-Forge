/// User-facing error categories. Repositories will return/throw these;
/// the UI shows [message] while [cause] is logged for developers.
sealed class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Check your internet connection and try again.',
    super.cause,
  }) : super(message);
}

final class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Something went wrong on our side. Please try again.',
    super.cause,
  }) : super(message);
}

final class StorageFailure extends Failure {
  const StorageFailure({
    String message = 'Could not read or save data on this device.',
    super.cause,
  }) : super(message);
}

/// The requested change clashes with existing data (e.g. duplicate SKU).
/// The message is safe to show to the user.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.cause});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    String message = 'An unexpected error occurred.',
    super.cause,
  }) : super(message);
}
