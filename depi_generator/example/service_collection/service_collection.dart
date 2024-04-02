import 'package:depi/depi.dart';

import '../services/abstract_service.dart';
import '../services/extended_class.dart';
import '../services/options_dependency.dart';
import '../services/single_class.dart';

part 'service_collection.depi.dart';

@serviceRegistrator
final class MyServiceProvider extends _$MyServiceProvider {
  // MyServiceProvider.development() : super._development();
  MyServiceProvider.production() : super._production();
  MyServiceProvider();

  @override
  void configureServices(ServiceProvider serviceProvider) {}
}
