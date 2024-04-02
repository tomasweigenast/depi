# Depi - Dart Dependency Injection

Depi is another dependency injection library that aims to match the functionality of .NET Dependency Injection.

## Table of Contents

- [Creating container](#creatincontainer)
- [Using services](#usingservices)
- [Service types](#servicetypes)
- [Options pattern](#optionspattern)
- [Generating code](#generatingcode)

## Getting Started<a name="creatincontainer"/>

Add you need to get started is create a new instance of `ServiceCollection`, which is a builder class that registers all the dependencies.

After creating a new `ServiceCollection` instance, start adding services:

```dart
final serviceCollection = ServiceCollection();
serviceCollection.putSingleton<HttpService>((services) => HttpService());
serviceCollection.putInstance<ServiceA>(ServiceA());
serviceCollection.putTransient<ServiceB>((services) => ServiceB());

serviceCollcetion..putTransient<ServiceD>((services) => ServiceD())
  ..putTransient<ServiceE>((services) => ServiceE())
  ..putTransient<ServiceF>((services) => ServiceF());
```

When finished, build the container and get an instance of `ServiceProvider`.

```dart
final ServiceProvider serviceProvider = serviceCollection.build();
```

If you want to modify the list of services after creating the container, consider calling:

```dart
final ModifiableServiceProvider serviceProvider = serviceCollection.buildModifiable();
```

This will give you access to the same methods to add services you have in the `ServiceCollection` class and some others to invalidate services, delete them and clear the container.

```dart

// This will delete HttpService
container.drop<HttpService>();

// This will invalidate the cached value for HttpService, if it is a lazy singleton.
container.invalidate<HttpService>();

// This will delete all the services
container.clear();
```

## Using services<a name="usingservices"/>

To retrieve a service, call:

```dart
final httpService = serviceProvider.service<HttpService>();
```

> Remember that this method will throw an exception if `HttpService` is not registered. If you don't want that and instead want to receive a null value, consider using `container.maybeService<HttpService>()`.

`ServiceProvider` is also a callable class, so you can do:

```dart
final httpService = serviceProvider<HttpService>();

// Benefit from using type inference
final HttpService httpService = serviceProvider();
```

## Service Types<a name="servicetypes"/>

Depi allows the creation of two service types:

- **Singleton**: A single instance to a type. It may be _lazy_, which means it will be created the next time it is requested, or a simple _value_, which is created when the service is registered.
- **Transient**: A new instance of the type will be created whenever the service is requested.

## Options Pattern<a name="optionspattern"/>

The options pattern is something that comes from .NET Dependency Injection. You can read more about it [here](https://learn.microsoft.com/en-us/dotnet/core/extensions/options), but, in general, it provides encapsulation and separation of concerns.

For example, if you create an `HttpService` you may want to allow the baseurl to be configured, so, you end up creating something like this:

```dart
HttpService({required String baseUrl}) : _baseUrl = baseUrl;
```

While this is not super bad, you can make it better using the _options pattern_. Start by creating a new class that will hold your "options" for the HttpService.

```dart
final class HttpServiceOptions {
  final String baseUrl;

  HttpServiceOptions({required this.baseUrl});
}
```

And now, update your HttpService to use the created class, but, the parameter must be of type `Options<T>`, so, in this case: `Options<HttpServiceOptions>`:

```dart
class HttpService {
  final HttpServiceOptions _options;

  HttpService({required Options<HttpServiceOptions> options}) : _options = options.value;
}
```

Now, to configure `HttpServiceOptions`, you have a couple of options:

```dart
// Provide a fixed, instantly created, value:
serviceProvider.configureValue<HttpServiceOptions>(HttpServiceOptions(baseUrl: "https:..."));

// Provide a fixed, lazy created, value:
serviceProvider.configure<HttpServiceOptions>((services) => HttpServiceOptions(baseUrl: "https:..."));

// Provide a transient, lazily created, value. Here, a new HttpServiceOptions will be created every time it is needed.
// Keep in mind this only will work if the service that requests this is also transient.
serviceProvider.configureSnapshot<HttpServiceOptions>((services) => HttpServiceOptions(baseUrl: "https:..."));
```

Finally, to request an instance of `HttpServiceOptions`, you call:

```dart
serviceProvider<Options<HttpServiceOptions>>();
```

If you are requesting it when creating a service, you can benefit from type inference and `DepiContainer` being a callable class and just call:

```dart
container.registerSingleton<HttpService>((services) => HttpService(options: services()));
```

> The same applies if you are requesting a service.

#### Why `Options<T>` instead of just `T`?

That is because you can create an `OptionsStream<T>`, which notifies you every time a new `T` Options is configured, **not** every time `T` changes.

To register a new `OptionsStream<T>`, call:

```dart
// Return an instance of T
serviceProvider.configureStream<T>((services) => T());
```

If `T` extends `ChangeNotifier`, `Depi` will automatically listen to its changes and push a new version of `T`, notifying every service that already has a version of `T`.
To use it, instead of passing `Options<T>` to your service constructor, pass an `OptionsStream<T>`:

```dart
class HttpService {
  HttpServiceOptions _options;

  HttpService({required OptionsStream<HttpServiceOptions> options}) : _options = options.value {
    options.onChange((newOptions) {
      _options = newOptions;
    });
  }
}
```

> `OptionsStream` always provides an initial value you can use in your constructor. Also, `value` always contains the up-to-date value.

## Generating Code<a name="generatingcode"/>

If you want to generate the registration methods automatically, install the following dependencies:

```
flutter pub add depi dev:depi_generator dev:build_runner
```

Create a new container class:

```dart
part of 'my_container.depi.dart';

@serviceRegistrator
final class MyServiceProvider extends _$MyServiceProvider {}
```

> The previous example is the minimal code needed to register services. You can also define environments creating named constructors.

### Environments

To create a new environment, simply define a new named constructor:

```dart
part of 'my_container.depi.dart';

@serviceRegistrator
final class MyServiceProvider extends _$MyServiceProvider {
  MyServiceProvider.development() : super.development();
  MyServiceProvider.production() : super.production();
}
```

> If you add the default constructor, you will have the 'default' environment. You can access use it in implementations using the `kDefaultEnvironment`.

### Configure services

If you want to configure options for your services, override the `configureServices` method and do your `configureX` calls there.

### Register services

To register a new service, annotate your class using either `@singleton` or `@transient` annotations. The implementations must be annotated
using the `@Implementation()` annotation, where you can also define the environment where the implementation will be registered:

```dart
@singleton
abstract class HttpService {}

@Implementation(environments: {"development"})
final class MockHttpService extends HttpService {}

@Implementation(environments: {"production"})
final class RealHttpService extends HttpService {}
```

If your service class is not `abstract` nor `interface` and you want to change the environment where the service is registered, simply annotate the class with the `Implementation` annotation too:

```dart
@singleton
@Implementation(environments: {kDefaultEnvironment, 'production'})
final class ServiceE {}
```

The same way you can override an implementation:

```dart
@singleton
final class ServiceB {}

@Implementation(environments: {"production"})
final class ServiceBImplementation extends ServiceB {}
```

If your service depends on `Options`, you don't need to annotate your options class, but make sure to configure the service in the `configureServices` method:

```dart
@singleton
final class ServiceC {
  final ServiceCOptions options;

  ServiceC({
    required Options<ServiceCOptions> options,
  }) : options = options.value;
}

// You need to configure this in configureServices!
final class ServiceCOptions {
  final String key;
  final int number;

  ServiceCOptions({required this.key, required this.number});
}
```

> More of this in the `example` folder of the `depi_generator` package

### Generating code

Finally, run `dart run build_runner build` to generate the code. To use the container, simply create a new instance of your ServiceRegistrator.
