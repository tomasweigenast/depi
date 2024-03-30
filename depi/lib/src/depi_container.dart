import 'package:depi/src/exception.dart';

part 'service.dart';

/// [DepiContainer] holds services and resolves instances when needed.
final class DepiContainer {
  final Map<Type, _Service> _services;

  /// A flag that indicates if an exception should be thrown when there is a duplicated service.
  final bool throwIfDuplicated;

  /// Creates a new [DepiContainer].
  DepiContainer({bool throwIfDuplicated = false}) : this._create({}, throwIfDuplicated);

  DepiContainer.scoped({DepiContainer? parent, bool throwIfDuplicated = false})
      : this._create(parent == null ? {} : parent._cloneServices(), throwIfDuplicated);

  DepiContainer._create(this._services, this.throwIfDuplicated);

  /// Registers a new lazy singleton.
  ///
  /// When [T] is requested, if it is the first time it is called, [create] will execute
  /// and its value will be saved for subsequent calls.
  void putSingleton<T>(ResolveFunc<T> create, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw ArgumentError("Service $T already registered.", "T");
    }

    _services[T] = _Service.lazy(create, false);
  }

  /// Registers a new transient value.
  ///
  /// Every time [T] is requested, [create] will execute and return its value.
  void putTransient<T>(ResolveFunc<T> create, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw ArgumentError("Service $T already registered.", "T");
    }

    _services[T] = _Service.lazy(create, true);
  }

  /// Registers a new singleton value.
  ///
  /// When [T] is requested, [value] is served.
  void putInstance<T>(T value, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw ArgumentError("Service $T already registered.", "T");
    }

    _services[T] = _Service.value(value);
  }

  /// Retrieves a service by [T], throwing an exception if the service is not found.
  T service<T>() {
    final service = _services[T];
    if (service == null) throw ServiceNotFoundException(T);
    return service.getValue(this) as T;
  }

  /// Retrieves a service by [T], returning null if the service is not found.
  T? maybeService<T>() {
    final service = _services[T];
    if (service == null) return null;
    return service.getValue(this) as T?;
  }

  Map<Type, _Service> _cloneServices() {
    final m = <Type, _Service>{};
    for (final MapEntry(:key, :value) in _services.entries) {
      if (value.getter == null) {
        m[key] = _Service.value(value.value);
      } else {
        m[key] = _Service.lazy(value.getter, value.transient);
      }
    }
    return m;
  }
}
