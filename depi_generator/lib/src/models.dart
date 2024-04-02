import 'package:depi/depi.dart';

final class ServiceDefinition {
  final int id;
  final String path;
  final String name;
  final ServiceType serviceType;
  final List<ServiceDependency> dependencies;
  final List<ServiceImplementation> implementations;

  /// Indicates if the class is abstract or interface
  final bool isBase;

  ServiceDefinition({
    required this.id,
    required this.path,
    required this.name,
    required this.serviceType,
    required this.dependencies,
    required this.isBase,
    required this.implementations,
  });

  factory ServiceDefinition.fromJson(Map map) => ServiceDefinition(
        id: map["id"] as int,
        path: map["path"] as String,
        name: map["name"] as String,
        serviceType: ServiceType.values[map["serviceType"] as int],
        dependencies: (map["dependencies"] as Iterable).map((e) => ServiceDependency.fromJson(e as Map)).toList(),
        isBase: map["isBase"] as bool,
        implementations: (map["implementations"] as Iterable).map((e) => ServiceImplementation.fromJson(e as Map)).toList(),
      );

  Map toJson() => {
        "id": id,
        "path": path,
        "name": name,
        "serviceType": serviceType.index,
        "dependencies": dependencies.map((e) => e.toJson()).toList(growable: false),
        "isBase": isBase,
        "implementations": implementations.map((e) => e.toJson()).toList(growable: false),
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

  ServiceImplementation({required this.typeId, required this.typeName, required this.environments});

  factory ServiceImplementation.fromJson(Map map) => ServiceImplementation(
        typeId: map["typeId"] as int,
        environments: (map["environments"] as Iterable).map((e) => e as String).toList(),
        typeName: map["typeName"] as String,
      );

  Map toJson() => {
        "typeId": typeId,
        "typeName": typeName,
        "environments": environments,
      };
}
