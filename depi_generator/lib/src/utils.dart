import 'package:analyzer/dart/element/element.dart';
import 'package:depi/depi.dart';
import 'package:source_gen/source_gen.dart';

const serviceAnnotation = TypeChecker.fromRuntime(Service);
const implementationAnnotation = TypeChecker.fromRuntime(Implementation);
const optionsType = TypeChecker.fromRuntime(Options);
const optionsStreamType = TypeChecker.fromRuntime(OptionsStream);

List<String> getImplementationAnnotationValues(Element element) {
  final annotations = implementationAnnotation.annotationsOf(element, throwOnUnresolved: false);
  final environments = annotations
      .map((e) => e.getField("environments")!.toSetValue()!.map((e) => e.toStringValue()!).toList())
      .fold(<String>[], (previousValue, element) => [...previousValue, ...element]);

  if (environments.isEmpty) {
    environments.add(kDefaultEnvironment);
  }

  return environments;
}
