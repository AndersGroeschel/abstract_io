import 'package:flutter/foundation.dart';
import 'package:abstract_io/abstract_io.dart';

/// makes this [AbstractIO] [Listenable]
///
/// this will notify listeners whenever new data is recieved via the
/// [onDataRecieved] function
///
/// [ValueListenableSupport] implements [ValueListenable] and is therefor
/// better to use but it can only be mixedin onto a [ValueStorage]
mixin ListenerSupport<W, R> on AbstractIO<W, R> implements Listenable {
  /// the list of listeners
  List<VoidCallback> _listeners = [];

  /// iterates through all the listeners and calls them / notifies them
  void notifyListeners() {
    for (VoidCallback listener in _listeners) {
      listener();
    }
  }

  /// adds a [listener] to the list of listeners if it is not null
  @override
  void addListener(listener) {
    if (listener == null) {
      return;
    }
    _listeners.add(listener);
  }

  /// removes the [listener] from the list of listeners
  @override
  void removeListener(listener) {
    _listeners.remove(listener);
  }

  @override
  @mustCallSuper
  void onDataRecieved(data) {
    super.onDataRecieved(data);
    notifyListeners();
  }
}

/// gives a default value for this [AbstractIO]
///
/// the [DefaultValue] mixin should be one of the last mixins applied for
/// it to work properly
///
/// when [onDataRecieved] is called with a null value then the [defaultValue] is
/// used instead for super.onDataRecieved
mixin DefaultValue<W, R> on AbstractIO<W, R> {
  /// the default value provided when none is passed in
  R get defaultValue;

  @override
  @mustCallSuper
  void onDataRecieved(data) {
    super.onDataRecieved(data ?? defaultValue);
  }
}
