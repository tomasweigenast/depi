/// Exception thrown by [DepiContainer] when a service is not found.
final class ServiceNotFoundException implements Exception {
  final String cause;
  ServiceNotFoundException(Type serviceType)
      : cause = "Service $serviceType not found.";

  @override
  String toString() => cause;
}

/// Exception thrown by [DepiContainer] when the user is trying to register a service
/// that is already registered.
final class DuplicatedServiceException implements Exception {
  final String cause;

  DuplicatedServiceException(Type serviceType)
      : cause = "Service $serviceType is already registered.";

  @override
  String toString() => cause;
}
