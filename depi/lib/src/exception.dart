/// Exception thrown by [DepiContainer] when a service is not found.
final class ServiceNotFoundException implements Exception {
  final String cause;
  ServiceNotFoundException(Type serviceType) : cause = "Service $serviceType not found.";
}
