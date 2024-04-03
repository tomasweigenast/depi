import 'package:depi/depi.dart';

import 'auth_service.dart';

@Implementation(environments: {"production"})
class ProductionAuthService implements AuthService {}
