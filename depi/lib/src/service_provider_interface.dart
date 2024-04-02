import 'package:depi/depi.dart';

part 'modifiable_service_provider.dart';
part 'options_impl.dart';
part 'service.dart';
part 'service_holder.dart';
part 'service_provider_builder.dart';
part 'service_provider_impl.dart';

/// [ServiceProvider] holds services and resolves instances when needed.
///
/// [ServiceProvider] uses the options pattern, a pattern that came from C#. You can read more about
/// it here: https://learn.microsoft.com/en-us/dotnet/core/extensions/options.
///
/// To create a new [ServiceProvider], use [ServiceCollection].
abstract class ServiceProvider extends _ServiceHolder {
  ServiceProvider._(super.services);

  /// Configures the [O] Options by specifying a fixed value.
  void configureValue<O extends Object>(O value);

  /// Configures the [O] Options by using a lazy callback
  void configure<O extends Object>(O Function(ServiceProvider container) configure);

  /// Configures the [O] Options by using a lazy transient callback. A new instance
  /// will be retrieved for the service every time it is requested.
  ///
  /// Keep in mind this will only work if the service that request this Options
  /// is configured as a transient service.
  void configureSnapshot<O extends Object>(O Function(ServiceProvider container) configure);

  /// Configures the [O] Options by using a lazy singleton callback.
  ///
  /// This Options will notify the services that are using it when it changes.
  void configureStream<O extends Object>(O Function(ServiceProvider container) configure);

  /// Updates the Options value for [O] if it was registered as a [OptionStream], otherwise,
  /// it will throw an exception.
  void changeOptions<O extends Object>(O Function(O old) callback);

  /// Retrieves a service by [T], throwing an exception if the service is not found.
  T service<T>();

  /// Retrieves a service by [T], returning null if the service is not found.
  T? maybeService<T>();

  T call<T>();
}
