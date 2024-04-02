import 'package:depi/depi.dart';

@singleton
@Implementation(environments: {kDefaultEnvironment, 'production'})
final class ServiceE {}

@singleton
abstract interface class ServiceD {}

@Implementation(environments: {"production", "development"})
final class ServiceDImplementation extends ServiceD {}

@singleton
@Implementation(environments: {"production"})
final class ServiceC {
  final ServiceE serviceE;
  final ServiceD serviceD;
  final ServiceCOptions options;

  ServiceC({
    required this.serviceE,
    required this.serviceD,
    required Options<ServiceCOptions> options,
  }) : options = options.value;
}

// You need to configure this in configureServices!
final class ServiceCOptions {
  final String key;
  final int number;

  ServiceCOptions({required this.key, required this.number});
}
