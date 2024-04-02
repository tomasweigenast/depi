part of 'service_provider_interface.dart';

final class ModifiableServiceProvider extends _ServiceProviderImpl with _ServiceRegistrator {
  ModifiableServiceProvider._internal(super.services);

  /// Drops a service, removing it from the list of available services.
  ///
  /// If the service is not registered, this does nothing.
  void delete<T>() => _services.remove(T);

  /// Invalidates the value created by a singleton, forcing the service to create a new
  /// one the next time it is requested.
  ///
  /// If [T] is not registed or it is not a lazy singleton, an exception will be thrown.
  void invalidate<T>() {
    final service = _services[T];
    if (service == null) throw ServiceNotFoundException(T);
    if (service.getter == null) throw ArgumentError("Service $T is not a lazy singleton.", "T");

    service.value = null;
  }

  /// Deletes all the registered services
  void clear() => _services.clear();
}
