part of 'service_provider_interface.dart';

typedef _ServiceCollection = Map<Type, _Service>;

abstract class _ServiceHolder {
  final _ServiceCollection _services;

  _ServiceHolder(this._services);
}

mixin _ServiceRegistrator on _ServiceHolder {
  /// Registers a new lazy singleton.
  ///
  /// When [T] is requested, if it is the first time it is called, [create] will execute
  /// and its value will be saved for subsequent calls.
  @pragma("vm:prefer-inline")
  void putSingleton<T>(ResolveFunc<T> create) {
    _services[T] = _Service.lazy(create, false);
  }

  //// Registers a new singleton value.
  ///
  /// When [T] is requested, [value] is served.
  @pragma("vm:prefer-inline")
  void putInstance<T>(T value) {
    _services[T] = _Service.value(value);
  }

  /// Registers a new transient value.
  ///
  /// Every time [T] is requested, [create] will execute and return its value.
  @pragma("vm:prefer-inline")
  void putTransient<T>(ResolveFunc<T> create) {
    _services[T] = _Service.lazy(create, true);
  }
}
