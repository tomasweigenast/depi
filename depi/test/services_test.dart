import 'package:depi/depi.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test("throw if service not found", () {
    final container = ServiceCollection().build();
    expect(() => container.service<HttpService>(), throwsException);
  });

  test("null if service not found", () {
    final container = ServiceCollection().build();
    expect(container.maybeService<HttpService>(), isNull);
  });

  test("register and get a singleton", () {
    final container = ServiceCollection()..putSingleton<HttpService>((p0) => HttpService());

    final serviceProvider = container.build();

    expect(serviceProvider.service<HttpService>().id, equals(serviceProvider.service<HttpService>().id));
  });

  test("register and get an instance", () {
    final container = ServiceCollection()..putInstance<HttpService>(HttpService());
    final serviceProvider = container.build();

    expect(serviceProvider.service<HttpService>().id, equals(serviceProvider.service<HttpService>().id));
  });

  test("register and get a transient", () {
    final container = ServiceCollection()..putTransient<HttpService>((p0) => HttpService());

    final serviceProvider = container.build();

    expect(serviceProvider.service<HttpService>().id, isNot(equals(serviceProvider.service<HttpService>().id)));
  });

  test("ModifiableServiceProvider", () {
    final container = ServiceCollection()..putTransient<HttpService>((p0) => HttpService());
    final serviceProvider = container.buildModifiable();

    expect(() => serviceProvider.putSingleton<AnAPI>((services) => AnAPI(httpService: services())), isNot(throwsA(isException)));
  });

  test("depend on services", () {
    final container = ServiceCollection()
      ..putSingleton<AnAPI>((services) => AnAPI(httpService: services<HttpService>()))
      ..putSingleton<HttpService>((services) => HttpService());

    final serviceProvider = container.build();

    expect(() => serviceProvider.service<AnAPI>(), isNot(throwsException));
    expect(serviceProvider.service<AnAPI>().httpService.id, equals(serviceProvider.service<HttpService>().id));
    expect(serviceProvider.service<AnAPI>().httpService.hashCode, equals(serviceProvider.service<HttpService>().hashCode));
  });

  test("options pattern", () {
    final container = ServiceCollection()
      ..putSingleton<HttpService>((services) => HttpService())
      ..putSingleton<JwtService>((services) => JwtService(httpService: services(), jwtSettings: services()));

    final serviceProvider = container.build();
    serviceProvider.configure<JwtSettings>((container) => JwtSettings(audience: "a", issuer: "b", password: "abc"));

    expect(serviceProvider<JwtService>().jwtSettings, equals(JwtSettings(audience: "a", issuer: "b", password: "abc")));
  });

  test("OptionsStream", () {
    final container = ServiceCollection()..putSingleton<ServiceB>((services) => ServiceB(settings: services()));

    final serviceProvider = container.build();
    serviceProvider.configureStream<JwtSettings>((container) => JwtSettings(audience: "a", issuer: "b", password: "abc"));

    expect(serviceProvider<ServiceB>().jwtSettings, equals(JwtSettings(audience: "a", issuer: "b", password: "abc")));

    serviceProvider.changeOptions<JwtSettings>(
      (oldValue) => JwtSettings(password: oldValue.password, audience: oldValue.audience, issuer: "ccc"),
    );
    expect(serviceProvider<ServiceB>().jwtSettings, equals(JwtSettings(audience: "a", issuer: "ccc", password: "abc")));
  });
}
