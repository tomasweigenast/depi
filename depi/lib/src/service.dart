part of 'service_provider_interface.dart';

typedef ResolveFunc<T> = T Function(ServiceProvider services);

final class _Service<T> {
  // Do not call this directly
  T? value;
  ResolveFunc<T>? getter;
  final bool transient;

  _Service.value(this.value) : transient = false;
  _Service.lazy(this.getter, this.transient);

  /// Resolves the value
  @pragma("vm:prefer-inline")
  T getValue(ServiceProvider container) {
    if (transient) return getter!(container);

    value ??= getter!(container);
    return value!;
  }
}
