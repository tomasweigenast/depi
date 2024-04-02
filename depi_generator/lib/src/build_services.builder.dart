import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:depi/depi.dart';
import 'package:depi_generator/src/models.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

const serviceRegistratorAnnotation =
    TypeChecker.fromRuntime(ServiceRegistrator);

class CollectionBuilder implements Builder {
  @override
  final buildExtensions = const {
    '.dart': ['.depi.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final lib = LibraryReader(await buildStep.inputLibrary);
    final annotated =
        lib.annotatedWith(serviceRegistratorAnnotation).toList(growable: false);

    if (annotated.length > 1) {
      throw "Cannot have more than 1 ServiceCollection.";
    }

    final exports = buildStep.findAssets(Glob('**/*.service.json'));
    final services = <int, ServiceDefinition>{};
    await for (final exportLibrary in exports) {
      final assetContent = await buildStep.readAsString(exportLibrary);
      for (final serviceDefinition in (jsonDecode(assetContent) as Iterable)
          .map((e) => ServiceDefinition.fromJson(e as Map))) {
        services[serviceDefinition.id] = serviceDefinition;
      }
    }

    if (annotated.isNotEmpty) {
      final source = DartFormatter().format(_buildServiceCollection(
          buildStep.inputId, annotated.first.element, services));
      buildStep.writeAsString(
          buildStep.inputId.changeExtension('.depi.dart'), source);
    }
  }

  static String _buildServiceCollection(
      AssetId assetId, Element element, Map<int, ServiceDefinition> services) {
    // write header
    final buf = StringBuffer(
        "// THIS WAS GENERATED BY depi_generator. DO NOT EDIT.\n\n");
    buf.writeln("part of '${p.basename(assetId.path)}';");
    // get the name of the class and get constructors to define environments
    final className = "_\$${element.displayName}";
    final constructorVisitor = _ConstructorVisitor();
    element.visitChildren(constructorVisitor);
    final namedConstructors = constructorVisitor.constructors
        .where((element) => element.name.isNotEmpty)
        .toList(growable: false);
    final unnamedConstructor = constructorVisitor.constructors
        .where((element) => element.name.isEmpty)
        .firstOrNull;

    if (namedConstructors
        .any((element) => element.displayName == kDefaultEnvironment)) {
      throw "Environments cannot be named $kDefaultEnvironment";
    }

    // get enabled environments
    final environments = {
      if (unnamedConstructor != null) kDefaultEnvironment,
      ...namedConstructors.map((e) => e.displayName.split(".")[1]),
    };

    // Check for invalid environments
    for (final service in services.values) {
      for (final implementation in service.implementations) {
        for (final implementationEnvironment in implementation.environments) {
          if (!environments.contains(implementationEnvironment)) {
            throw "Environment $implementationEnvironment is not a valid environment.";
          }
        }
      }
    }

    buf.writeln("abstract base class $className extends ServiceCollection {");

    // Write environments methods and constructors
    for (final environment
        in environments.where((element) => element != kDefaultEnvironment)) {
      buf.writeln("$className._$environment() {");
      _writeServiceRegister(buf, environment, services);
      buf.writeln("}");
    }

    // Write default constructor
    if (unnamedConstructor != null) {
      buf.writeln("$className() {");

      // write services defined in the default environment
      _writeServiceRegister(buf, kDefaultEnvironment, services);

      buf.writeln("}");
    }

    buf.writeln("void configureServices(ServiceProvider serviceProvider);");

    buf.writeln("""
@override
  ServiceProvider build() {
    final serviceProvider = super.build();
    configureServices(serviceProvider);
    return serviceProvider;
  }
""");
    buf.writeln("}");

    return buf.toString();
  }

  /// writes to [buf] a putSingleton or putTransient method for every service in [services].
  static void _writeServiceRegister(StringBuffer buf, String environment,
      Map<int, ServiceDefinition> services) {
    for (final MapEntry(value: service) in services.entries) {
      // Get implementations for the service
      final implementations = service.implementations
          .where((element) => element.environments.contains(environment))
          .toList();

      // just ignore if the service does not have an implementation for the current environment
      if (implementations.isEmpty) continue;

      if (implementations.length > 1) {
        throw "Service ${service.name} has more than one implementation for the environment '$environment'.";
      }

      final putMethod = switch (service.serviceType) {
        ServiceType.singleton => "putSingleton",
        ServiceType.transient => "putTransient",
      };

      buf.writeln(
          "$putMethod<${service.name}>((services) => ${implementations.firstOrNull?.typeName ?? service.name}(");
      for (final dependency in service.dependencies) {
        final dependencyService = services[dependency.typeId];
        if (!dependency.isOptions && dependencyService == null) {
          throw "Service '${service.name}' depends on '${dependency.serviceName}' (parameter ${dependency.parameterName}) which is not found.";
        }

        if (dependencyService != null &&
            !dependencyService.implementations
                .any((element) => element.environments.contains(environment))) {
          throw "Service '${service.name}' depends on '${dependency.serviceName}' which is not defined in the environment $environment.";
        }
        buf.write("${dependency.parameterName}: services(),");
      }
      buf.writeln("));");
    }
  }
}

final class _ConstructorVisitor extends SimpleElementVisitor {
  final List<ConstructorElement> constructors = [];

  @override
  void visitConstructorElement(ConstructorElement element) {
    constructors.add(element);
  }
}