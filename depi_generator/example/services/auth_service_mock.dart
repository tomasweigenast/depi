import 'package:depi/depi.dart';

import 'auth_service.dart';

@Implementation(environments: {"development"})
class MockAuthService implements AuthService {}
