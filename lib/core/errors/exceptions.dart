class AppException implements Exception {
  final String message;
  final String? code;
  const AppException({required this.message, this.code});
  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection', super.code});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Resource not found', super.code});
}

class PermissionException extends AppException {
  const PermissionException({super.message = 'Permission denied', super.code});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.code});
}

class CacheException extends AppException {
  const CacheException({super.message = 'Local cache error', super.code});
}

class LocationException extends AppException {
  const LocationException({super.message = 'Location unavailable', super.code});
}
