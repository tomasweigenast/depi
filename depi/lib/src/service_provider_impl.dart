part of 'service_provider_interface.dart';

/// The default implementation of [ServiceProvider]
final class _ServiceProviderImpl extends ServiceProvider {
  _ServiceProviderImpl(super.services) : super._();

  /// Configures the [O] Options by specifying a fixed value.
  @override
  void configureValue<O extends Object>(O value) =>
      _services[Options<O>] = _Service.value(_OptionValue(value));

  /// Configures the [O] Options by using a lazy callback
  @override
  void configure<O extends Object>(
          O Function(ServiceProvider container) configure) =>
      _services[Options<O>] =
          _Service.lazy((services) => _OptionValue(configure(services)), false);

  /// Configures the [O] Options by using a lazy transient callback. A new instance
  /// will be retrieved for the service every time it is requested.
  ///
  /// Keep in mind this will only work if the service that request this Options
  /// is configured as a transient service.
  @override
  void configureSnapshot<O extends Object>(
          O Function(ServiceProvider container) configure) =>
      _services[Options<O>] =
          _Service.lazy((services) => _OptionValue(configure(services)), true);

  /// Configures the [O] Options by using a lazy singleton callback.
  ///
  /// This Options will notify the services that are using it when it changes.
  @override
  void configureStream<O extends Object>(
          O Function(ServiceProvider container) configure) =>
      _services[OptionsStream<O>] = _Service.lazy(
          (services) => _OptionStream(configure(services)), false);

  /// Updates the Options value for [O] if it was registered as a [OptionStream], otherwise,
  /// it will throw an exception.
  @override
  void changeOptions<O extends Object>(O Function(O old) callback) {
    final options = _services[OptionsStream<O>];
    if (options == null) throw ServiceNotFoundException(O);
    final optionsStream = options.value as _OptionStream<O>;
    optionsStream._setValue(callback(optionsStream._currentValue));
  }

  /// Retrieves a service by [T], throwing an exception if the service is not found.
  @override
  T service<T>() {
    try {
      return _services[T]!.getValue(this) as T;
    } catch (_) {
      throw ServiceNotFoundException(T);
    }
  }

  /// Retrieves a service by [T], returning null if the service is not found.
  @override
  @pragma("vm:prefer-inline")
  T? maybeService<T>() => _services[T]?.getValue(this) as T?;

  @pragma("vm:prefer-inline")
  @override
  T call<T>() => service<T>();
}
