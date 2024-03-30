part of 'depi_container.dart';

final class _OptionValue<T extends Object> implements Options<T> {
  final T _value;

  _OptionValue(this._value);

  @override
  T get value => _value;
}
