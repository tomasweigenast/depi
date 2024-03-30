import 'package:depi/src/depi_container.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test("throw if service not found", () {
    final container = DepiContainer();
    expect(() => container.service<HttpService>(), throwsException);
  });

  test("null if service not found", () {
    final container = DepiContainer();
    expect(container.maybeService<HttpService>(), isNull);
  });

  test("register and get a singleton", () {
    final container = DepiContainer();
    container.putSingleton<HttpService>((p0) => HttpService());

    expect(container.service<HttpService>().id, equals(container.service<HttpService>().id));
  });

  test("register and get an instance", () {
    final container = DepiContainer();
    container.putInstance<HttpService>(HttpService());

    expect(container.service<HttpService>().id, equals(container.service<HttpService>().id));
  });

  test("register and get a transient", () {
    final container = DepiContainer();
    container.putTransient<HttpService>((p0) => HttpService());

    expect(container.service<HttpService>().id, isNot(equals(container.service<HttpService>().id)));
  });

  test("throw if duplicated", () {
    final container = DepiContainer(throwIfDuplicated: true);
    container.putTransient<HttpService>((p0) => HttpService());
    expect(() => container.putTransient<HttpService>((p0) => HttpService()), throwsException);
    expect(() => container.putSingleton<HttpService>((p0) => HttpService()), throwsException);
  });

  test("replace if duplicated", () {
    final container = DepiContainer();
    container.putInstance<HttpService>(HttpService());
    final firstId = container.service<HttpService>().id;
    container.putInstance<HttpService>(HttpService());
    final secondId = container.service<HttpService>().id;

    expect(firstId, isNot(equals(secondId)));
  });

  test("depend on services", () {
    final container = DepiContainer();
    container.putSingleton<AnAPI>((services) => AnAPI(httpService: services<HttpService>()));
    container.putSingleton<HttpService>((services) => HttpService());

    expect(() => container.service<AnAPI>(), isNot(throwsException));
    expect(container.service<AnAPI>().httpService.id, equals(container.service<HttpService>().id));
    expect(container.service<AnAPI>().httpService.hashCode, equals(container.service<HttpService>().hashCode));
  });

  test("options pattern", () {
    final container = DepiContainer();
    container.putSingleton<HttpService>((services) => HttpService());
    container.putSingleton<JwtService>((services) => JwtService(httpService: services(), jwtSettings: services()));
    container.configure<JwtSettings>((container) => JwtSettings(audience: "a", issuer: "b", password: "abc"));

    expect(container<JwtService>().jwtSettings, equals(JwtSettings(audience: "a", issuer: "b", password: "abc")));
  });
}
