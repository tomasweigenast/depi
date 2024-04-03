import 'package:meta/meta_meta.dart';

/// The default environment name
const kDefaultEnvironment = "default";

/// An annotation used in classes that are services.
///
/// If the class being annotated can be instantiated, the environment can be set using the [Environment] annotation, otherwise,
/// use the [Implementation] annotation in the implementation classes.
@Target({TargetKind.classType})
final class Service {
  final ServiceType type;

  const Service({required this.type});
}

/// An annotation used in classes that are concrete implementation of services.
@Target({TargetKind.classType})
final class Implementation {
  /// The list of environments where this implementation is injected
  final Set<String> environments;

  /// The service type this is an implementation for.
  final Type? service;

  const Implementation({required this.environments, this.service});
}

/// An annotation used in the class that will be the dependency container
@Target({TargetKind.classType})
final class ServiceRegistrator {
  const ServiceRegistrator();
}

enum ServiceType {
  singleton,
  transient,
}

/// A [Service] annotation that is a singleton service
const singleton = Service(type: ServiceType.singleton);

/// A [Service] annotation that is a transient service
const transient = Service(type: ServiceType.transient);

/// The default [ServiceRegistrator] annotation
const serviceRegistrator = ServiceRegistrator();

/// An annotation that indicates the implementation of a class in the default environment
const implementation = Implementation(environments: {kDefaultEnvironment});
