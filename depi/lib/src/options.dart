/// Provides the [T] value to a service.
abstract interface class Options<T extends Object> {
  /// Resolves to the configured [T] for the service.
  T get value;
}

/// Provides the [T] value to a service also watching for changes on [T]
abstract interface class OptionsStream<T extends Object> extends Options<T> {
  /// Called when [T] changes or has a new value.
  void onChange(void Function(T newOptions) callback);
}
