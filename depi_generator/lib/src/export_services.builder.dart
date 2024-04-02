import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:depi/depi.dart';
import 'package:depi_generator/src/models.dart';
import 'package:depi_generator/src/utils.dart';
import 'package:source_gen/source_gen.dart';

final class ExportServicesBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.service.json'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final lib = LibraryReader(await buildStep.inputLibrary);
    final services = <int, ServiceDefinition>{};

    // Get services
    for (final serviceLibrary in lib.annotatedWith(serviceAnnotation)) {
      final serviceClass = serviceLibrary.element;
      if (serviceClass is! ClassElement) continue;

      if (serviceClass.isMixinClass) throw "Mixin classes cannot be services. Conflict wiht ${serviceClass.displayName}.";

      final visitor = _ElementVisitor();
      serviceClass.visitChildren(visitor);

      // Get the type of services
      final serviceType = ServiceType.values[serviceLibrary.annotation.read("type").objectValue.getField("index")!.toIntValue()!];

      // Check for dependencies in the service
      final dependencies = <ServiceDependency>[];
      for (final argument in visitor.parameters) {
        final visitor = _TypeVisitor();
        argument.type.accept(visitor);
        dependencies.add(
          ServiceDependency(
            typeId: visitor.typeId,
            parameterName: argument.name,
            serviceName: visitor.typeName,
            isOptions: optionsType.isAssignableFromType(argument.type) || optionsStreamType.isAssignableFromType(argument.type),
          ),
        );
      }

      // create the definition
      services[serviceClass.id] = ServiceDefinition(
        id: serviceClass.id,
        path: buildStep.inputId.path,
        name: serviceClass.displayName,
        isBase: !serviceClass.isConstructable,
        serviceType: serviceType,
        dependencies: dependencies,
        implementations: [
          // If the class can be instantiated, it must be an implementation
          if (serviceClass.isConstructable)
            ServiceImplementation(
              typeId: serviceClass.id,
              typeName: serviceClass.displayName,
              environments: getImplementationAnnotationValues(serviceClass),
            ),
        ],
      );
    }

    // Get concrete implementations
    for (final implementationLibrary in lib.annotatedWith(implementationAnnotation)) {
      final implementationClass = implementationLibrary.element;
      if (implementationClass is! ClassElement) continue;
      if (!implementationClass.isConstructable) {
        throw "Implementations must be instantiable. Conflict with ${implementationClass.displayName}.";
      }

      if (implementationClass.supertype == null) {
        throw "Implementations must have a superclass that is the service being implemented. Conflict with ${implementationClass.displayName}.";
      }

      // ignore this class if already marked as an implementation
      if (implementationClass.isConstructable && services.containsKey(implementationClass.id)) {
        continue;
      }

      // Read environments where this is defined
      final environments = implementationLibrary.annotation.read("environments").setValue.map((e) => e.toStringValue()!).toList();

      final serviceId = implementationClass.supertype!.element.id;
      final service = services[serviceId];

      if (service == null) {
        throw "Service ${implementationClass.supertype!.element.displayName} not found. Class probably not marked as @Service";
      }

      service.implementations.add(
        ServiceImplementation(
          typeId: implementationClass.id,
          typeName: implementationClass.displayName,
          environments: environments,
        ),
      );
    }

    if (services.isNotEmpty) {
      buildStep.writeAsString(
        buildStep.inputId.changeExtension('.service.json'),
        jsonEncode(services.values.map((value) => value.toJson()).toList(growable: false)),
      );
    }
  }
}

final class _ElementVisitor extends SimpleElementVisitor {
  final List<ParameterElement> parameters = [];

  @override
  void visitConstructorElement(ConstructorElement element) {
    parameters.addAll(element.parameters);
  }
}

final class _TypeVisitor extends UnifyingTypeVisitor {
  late int typeId;
  late String typeName;

  @override
  void visitDartType(DartType type) {
    if (type is InterfaceType) {
      typeId = type.element.id;
      typeName = type.element.displayName;
    }
  }
}
