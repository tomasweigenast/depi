part of 'depi_container.dart';

final class _OptionValue<T extends Object> implements Options<T> {
  final T _value;

  _OptionValue(this._value);

  @override
  T get value => _value;
}

final class _OptionStream<T extends Object> implements OptionsStream<T> {
  T _currentValue;
  final List<void Function(T newOptions)> callbacks = [];

  _OptionStream(this._currentValue);

  @override
  T get value => _currentValue;

  @override
  void onChange(void Function(T newOptions) callback) => callbacks.add(callback);

  void _setValue(T newValue) {
    _currentValue = newValue;
    for (final callback in callbacks) {
      callback(newValue);
    }
  }

  void dispose() {
    callbacks.clear();
  }
}
