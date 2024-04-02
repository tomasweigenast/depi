import 'package:depi/depi.dart';

@transient
abstract class AbstractService {}

@Implementation(environments: {"production"})
final class ConcreteA extends AbstractService {}

@Implementation(environments: {"development"})
final class ConcreteB extends AbstractService {}
