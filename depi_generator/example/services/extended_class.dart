import 'package:depi/depi.dart';

@singleton
final class ServiceB {}

@Implementation(environments: {"production"})
final class ServiceBImplementation extends ServiceB {}
