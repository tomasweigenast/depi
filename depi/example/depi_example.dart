import 'dart:math';

import 'package:depi/depi.dart';

void main() {
  final container = ServiceCollection();
  container.putSingleton((services) => HttpService());
  container.putSingleton((services) => AnAPI(httpService: services<HttpService>()));
  container.putTransient(
    (services) => JwtService(
      jwtSettings: services(),
      httpService: services(),
    ),
  );

  final serviceProvider = container.build();
  serviceProvider.configure<JwtSettings>((container) => JwtSettings(audience: "a", issuer: "a", password: "123"));

  final jwtService = serviceProvider.service<JwtService>();
  print(jwtService.jwtSettings);
}

final random = Random.secure();
int randomId() => random.nextInt(1 << 32);

final class HttpService {
  final int id;

  HttpService() : id = randomId();
}

final class AnAPI {
  final HttpService httpService;

  AnAPI({required this.httpService});
}

final class JwtSettings {
  final String password;
  final String audience;
  final String issuer;

  JwtSettings({required this.password, required this.audience, required this.issuer});

  @override
  int get hashCode => Object.hash(password, audience, issuer);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JwtSettings && other.password == password && other.audience == audience && other.issuer == issuer);
}

final class JwtService {
  final JwtSettings jwtSettings;
  final HttpService httpService;

  JwtService({
    required this.httpService,
    required Options<JwtSettings> jwtSettings,
  }) : jwtSettings = jwtSettings.value;
}
