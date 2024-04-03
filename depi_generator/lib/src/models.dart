import 'package:depi/depi.dart';

final class Build {
  final Map<String, ServiceDefinition> services;
  final List<ServiceImplementation> implementations;

  Build({required this.services, required this.implementations});

  factory Build.fromJson(Map map) => Build(
        services: (map["services"] as Map).map((key, value) => MapEntry(key, ServiceDefinition.fromJson(value))),
        implementations: (map["implementations"] as Iterable).map((e) => ServiceImplementation.fromJson(e)).toList(),
      );

  Map toJson() => {
        "services": services.map((key, value) => MapEntry(key, value.toJson())),
        "implementations": implementations.map((e) => e.toJson()).toList(),
      };
}

final class ServiceDefinition {
  final String path;
  final String name;
  final ServiceType serviceType;
  final List<ServiceDependency> dependencies;

  /// Indicates if the class is abstract or interface
  final bool isBase;

  ServiceDefinition({
    required this.path,
    required this.name,
    required this.serviceType,
    required this.dependencies,
    required this.isBase,
  });

  factory ServiceDefinition.fromJson(Map map) => ServiceDefinition(
        path: map["path"] as String,
        name: map["name"] as String,
        serviceType: ServiceType.values[map["serviceType"] as int],
        dependencies: (map["dependencies"] as Iterable).map((e) => ServiceDependency.fromJson(e as Map)).toList(),
        isBase: map["isBase"] as bool,
      );

  Map toJson() => {
        "path": path,
        "name": name,
        "serviceType": serviceType.index,
        "dependencies": dependencies.map((e) => e.toJson()).toList(growable: false),
        "isBase": isBase,
      };
}

final class ServiceDependency {
  final int typeId;
  final String parameterName;
  final String serviceName;
  final bool isOptions;

  ServiceDependency({required this.typeId, required this.parameterName, required this.serviceName, required this.isOptions});

  factory ServiceDependency.fromJson(Map map) => ServiceDependency(
        typeId: map["typeId"] as int,
        parameterName: map["parameterName"] as String,
        serviceName: map["serviceName"] as String,
        isOptions: map["isOptions"] as bool,
      );

  Map toJson() => {
        "typeId": typeId,
        "parameterName": parameterName,
        "serviceName": serviceName,
        "isOptions": isOptions,
      };
}

final class ServiceImplementation {
  final int typeId;
  final List<String> environments;
  final String typeName;
  final String forServiceName;

  ServiceImplementation({
    required this.typeId,
    required this.typeName,
    required this.environments,
    required this.forServiceName,
  });

  factory ServiceImplementation.fromJson(Map map) => ServiceImplementation(
        typeId: map["typeId"] as int,
        environments: (map["environments"] as Iterable).map((e) => e as String).toList(),
        typeName: map["typeName"] as String,
        forServiceName: map["forServiceName"] as String,
      );

  Map toJson() => {
        "typeId": typeId,
        "typeName": typeName,
        "environments": environments,
        "forServiceName": forServiceName,
      };
}
