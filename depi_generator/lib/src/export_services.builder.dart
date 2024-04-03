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

    final discoveredServices = <String, ServiceDefinition>{};
    final implementations = <ServiceImplementation>[];

    // Get services
    for (final serviceLibrary in lib.annotatedWith(serviceAnnotation)) {
      final serviceClass = serviceLibrary.element;
      if (serviceClass is! ClassElement) continue;

      if (serviceClass.isMixinClass) {
        throw "Mixin classes cannot be services. Conflict with ${serviceClass.displayName}.";
      }

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
      // If the class can be instantiated, it must be an implementation
      if (serviceClass.isConstructable) {
        implementations.add(
          ServiceImplementation(
            typeId: serviceClass.id,
            typeName: serviceClass.displayName,
            forServiceName: serviceClass.displayName,
            environments: getImplementationAnnotationValues(serviceClass),
          ),
        );
      }

      // create the definition
      discoveredServices[serviceClass.name] = ServiceDefinition(
        path: buildStep.inputId.path,
        name: serviceClass.displayName,
        isBase: !serviceClass.isConstructable,
        serviceType: serviceType,
        dependencies: dependencies,
      );
    }

    // Get concrete implementations
    for (final implementationLibrary in lib.annotatedWith(implementationAnnotation)) {
      final implementationClass = implementationLibrary.element;
      final implementationAnnotation = implementationLibrary.annotation;
      if (implementationClass is! ClassElement) continue;
      if (!implementationClass.isConstructable) {
        throw "Implementations must be instantiable. Conflict with ${implementationClass.displayName}.";
      }

      // ignore this class if already marked as an implementation
      if (implementationClass.isConstructable && discoveredServices.containsKey(implementationClass.displayName)) {
        continue;
      }

      String? forServiceName;
      try {
        final baseServiceType = implementationAnnotation.read("type").typeValue.element!.displayName;
        forServiceName = baseServiceType;
      } catch (_) {}

      // try to get service from interface
      if (forServiceName == null &&
          implementationClass.supertype?.isDartCoreObject == true &&
          implementationClass.interfaces.isNotEmpty) {
        try {
          final interface = implementationClass.interfaces.single;
          forServiceName = interface.element.displayName;
        } catch (_) {
          throw "Unable to know which service is ${implementationClass.displayName} implementation for. Specify the service type in the Implementation attribute.";
        }
      } else {
        forServiceName = implementationClass.supertype!.element.displayName;
      }

      // Read environments where this is defined
      final environments = implementationAnnotation.read("environments").setValue.map((e) => e.toStringValue()!).toList();

      implementations.add(
        ServiceImplementation(
          typeId: implementationClass.id,
          typeName: implementationClass.displayName,
          forServiceName: forServiceName,
          environments: environments,
        ),
      );
    }

    if (discoveredServices.isNotEmpty || implementations.isNotEmpty) {
      buildStep.writeAsString(
        buildStep.inputId.changeExtension('.service.json'),
        jsonEncode(Build(
          implementations: implementations,
          services: discoveredServices,
        )),
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
