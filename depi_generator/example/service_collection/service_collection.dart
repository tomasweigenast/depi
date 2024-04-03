import 'package:depi/depi.dart';

import '../services/abstract_service.dart';
import '../services/auth_service.dart';
import '../services/auth_service_impl.dart';
import '../services/auth_service_mock.dart';
import '../services/extended_class.dart';
import '../services/options_dependency.dart';
import '../services/single_class.dart';

part 'service_collection.depi.dart';

@serviceRegistrator
final class MyServiceCollection extends _$MyServiceCollection {
  MyServiceCollection.development() : super._development();
  MyServiceCollection.production() : super._production();
  MyServiceCollection();

  @override
  void configureServices(ServiceProvider serviceProvider) {}
}
