import 'package:depi/depi.dart';

part 'options_impl.dart';
part 'service.dart';

/// [DepiContainer] holds services and resolves instances when needed.
///
/// [DepiContainer] uses the options pattern, a pattern that came from C#. You can read more about
/// it here: https://learn.microsoft.com/en-us/dotnet/core/extensions/options
final class DepiContainer {
  final Map<Type, _Service> _services;

  /// A flag that indicates if an exception should be thrown when there is a duplicated service.
  final bool throwIfDuplicated;

  /// Creates a new [DepiContainer].
  DepiContainer({bool throwIfDuplicated = false}) : this._create({}, throwIfDuplicated);

  /// Creates a clone of another [DepiContainer].
  DepiContainer.clone(DepiContainer parent, {bool throwIfDuplicated = false})
      : this._create(parent._cloneServices(), throwIfDuplicated);

  DepiContainer._create(this._services, this.throwIfDuplicated);

  /// Registers a new lazy singleton.
  ///
  /// When [T] is requested, if it is the first time it is called, [create] will execute
  /// and its value will be saved for subsequent calls.
  ///
  /// If [replace] is true and [T] is already registered, it will be replaced with this new service.
  void putSingleton<T>(ResolveFunc<T> create, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw DuplicatedServiceException(T);
    }

    _services[T] = _Service.lazy(create, false);
  }

  /// Registers a new transient value.
  ///
  /// Every time [T] is requested, [create] will execute and return its value.
  /// If [replace] is true and [T] is already registered, it will be replaced with this new service.
  void putTransient<T>(ResolveFunc<T> create, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw DuplicatedServiceException(T);
    }

    _services[T] = _Service.lazy(create, true);
  }

  /// Registers a new singleton value.
  ///
  /// When [T] is requested, [value] is served.
  /// If [replace] is true and [T] is already registered, it will be replaced with this new service.
  void putInstance<T>(T value, {bool replace = false}) {
    if (!replace && throwIfDuplicated && _services.containsKey(T)) {
      throw DuplicatedServiceException(T);
    }

    _services[T] = _Service.value(value);
  }

  /// Configures the [O] Options by specifying a fixed value.
  void configureValue<O extends Object>(O value) {
    _services[Options<O>] = _Service.value(_OptionValue(value));
  }

  /// Configures the [O] Options by using a lazy callback
  void configure<O extends Object>(O Function(DepiContainer container) configure) {
    _services[Options<O>] = _Service.lazy((services) => _OptionValue(configure(services)), false);
  }

  /// Configures the [O] Options by using a lazy transient callback. A new instance
  /// will be retrieved for the service every time it is requested.
  ///
  /// Keep in mind this will only work if the service that request this Options
  /// is configured as a transient service.
  void configureSnapshot<O extends Object>(O Function(DepiContainer container) configure) {
    _services[Options<O>] = _Service.lazy((services) => _OptionValue(configure(services)), true);
  }

  /// Configures the [O] Options by using a lazy singleton callback.
  ///
  /// This Options will notify the services that are using it when it changes.
  void configureStream<O extends Object>(O Function(DepiContainer container) configure) {
    _services[OptionsStream<O>] = _Service.lazy((services) => _OptionStream(configure(services)), false);
  }

  /// Updates the Options value for [O] if it was registered as a [OptionStream], otherwise,
  /// it will throw an exception.
  void changeOptions<O extends Object>(O Function(O old) callback) {
    final options = _services[OptionsStream<O>];
    if (options == null) throw ServiceNotFoundException(O);
    final optionsStream = options.value as _OptionStream<O>;
    optionsStream._setValue(callback(optionsStream._currentValue));
  }

  /// Drops a service, deleting it.
  ///
  /// If the service is not registered, this does nothing.
  void drop<T>() {
    final service = _services.remove(T);
    if (service?.value is _OptionStream) {
      (service!.value as _OptionStream).dispose();
    }
  }

  /// Invalidates the value created by a singleton, forcing the service to create a new
  /// one the next time it is requested.
  ///
  /// If [T] is not registed or it is not a lazy singleton, an exception will be thrown.
  void invalidate<T>() {
    final service = _services[T];
    if (service == null) {
      throw ServiceNotFoundException(T);
    }

    if (service.getter == null) throw ArgumentError("Service $T is not registered as a lazy singleton.", T.toString());
    service.value = null;
  }

  /// Deletes all the registered services
  void clear() => _services.clear();

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

  /// Retrieves the Options<[T]>
  @pragma("vm:prefer-inline")
  Options<T> options<T extends Object>() => service<Options<T>>();

  @pragma("vm:prefer-inline")
  T call<T>() => service<T>();

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
