part of 'service_provider_interface.dart';

final class ServiceCollection extends _ServiceHolder with _ServiceRegistrator {
  ServiceCollection() : super({});

  /// Builds a [ServiceProvider] with the registered services.
  ServiceProvider build() => _ServiceProviderImpl(_ServiceCollection.from(_services));

  /// Builds a [ServiceProvider] that can be modified after its creation, adding or removing services.
  ModifiableServiceProvider buildModifiable() => ModifiableServiceProvider._internal(_ServiceCollection.from(_services));
}
