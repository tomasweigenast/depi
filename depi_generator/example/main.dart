import 'service_collection/service_collection.dart';
import 'services/abstract_service.dart';

void main() {
  final serviceProvider = MyServiceProvider.production().build();
  // serviceProvider.service<AbstractService>();
}
