abstract class Failure {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});

  @override
  bool operator ==(Object other) =>
      other is Failure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() => '${runtimeType}(code: $code, message: $message)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found', super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied', super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local cache error', super.code});
}

class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Location unavailable', super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unexpected error occurred', super.code});
}
