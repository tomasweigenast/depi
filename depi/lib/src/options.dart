/// Provides the [T] value to a service.
abstract interface class Options<T extends Object> {
  /// Resolves to the configured [T] for the service.
  T get value;
}
