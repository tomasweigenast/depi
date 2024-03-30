# Depi - Dart Dependency Injection

Depi is another dependency injection library that aims to match the functionality of .NET Dependency Injection.

## Table of Contents
- [Getting started](#gettingstarted)
  - [Adding services](#addingservices)
  - [Retrieve services](#retrieveservices)
  - [Removing services](#removingservices)
- [Service types](#service-types)
- [Options pattern](#options-pattern)

## Getting Started<a name="gettingstarted"/>

### Adding services<a name="addingservices"/>
Start by creating a new instance of `DepiContainer` and start adding services:
```dart
final container = DepiContainer();
container.putSingleton<HttpService>((services) => HttpService());
container.putInstance<ServiceA>(ServiceA());
container.putTransient<ServiceB>((services) => ServiceB());
```

### Retrieve services<a name="retrieveservices"/>
To retrieve a previously added service, call:
```dart
final httpService = container.service<HttpService>();
```
> Remember that this method will throw an exception if `HttpService` is not registered. If you don't want that and instead want to receive a null value, consider using `container.maybeService<HttpService>()`.

### Dropping and invalidating a service<a name="removingservices"/>
If you don't want to have a service registered anymore, call:
```dart
container.drop<HttpService>();
```
> If the service is not registered, this is a no-op.

On the other hand, if you want to invalidate the value created by a lazy singleton, call:
```dart
container.invalidate<HttpService>();
```
> This method will throw if the service is not found or the service is not a lazy singleton.

## Service Types
Depi allows the creation of two service types:
- **Singleton**: A single instance to a type. It may be _lazy_, which means it will be created the next time it is requested, or a simple _value_, which is created when the service is registered.
- **Transient**: A new instance of the type will be created whenever the service is requested.

## Options Pattern
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
container.configureValue<HttpServiceOptions>(HttpServiceOptions(baseUrl: "https:..."));

// Provide a fixed, lazy created, value:
container.configure<HttpServiceOptions>((services) => HttpServiceOptions(baseUrl: "https:..."));

// Provide a transient, lazy created, value. Here, a new HttpServiceOptions will be created every time it is needed.
// Keep in mind this only will work if the service that request this is also transient.
container.configureSnapshot<HttpServiceOptions>((services) => HttpServiceOptions(baseUrl: "https:..."));
```

Finally, to request an instance of `HttpServiceOptions`, you call:
```dart
container.option<HttpServiceOptions>();
```

If you are requesting it when creating a service, you can benefit of type inference and `DepiContainer` being a callable class and just call:
```dart
container.registerSingleton<HttpService>((services) => HttpService(options: services()));
```
> The same applies if you are requesting a service.

#### Why `Options<T>` instead of just `T`?
That is because you can create a `OptionsStream<T>`, which notifies every time a new `T` options is configured, **not** every time `T` changes. If you want to notify every time `T` changes, make sure `T` extends `ChangeNotifier`.

To register a new `OptionsStream<T>`, call:
```dart
// Return an instance of T
container.configureStream<T>((services) => T());
```
If `T` extends `ChangeNotifier`, `Depi` will automatically listen to it changes and push a new version of `T`, notifying every service that already has a version of `T`.
To use it, instead of passing `Options<T>` to your service constructor, pass a `OptionsStream<T>`:
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

> `OptionsStream` always provides an initial value you can use in your constructor. Also, `value` always contains the up to date value.
