/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Failure related to server/API issues
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

/// Failure related to local database
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

/// Failure related to network connectivity
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

/// Failure related to authentication
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

/// Failure related to validation
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

/// Failure when resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.code]);
}

/// Failure related to permissions
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

/// Unexpected/unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}
