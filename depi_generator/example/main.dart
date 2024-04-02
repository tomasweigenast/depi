import 'service_collection/service_collection.dart';
import 'services/abstract_service.dart';

void main() {
  final serviceProvider = MyServiceCollection.production().build();
  serviceProvider.service<AbstractService>();
}
