import 'dart:math' show Random;
import 'package:abstract_io/abstract_io.dart';
import 'package:flutter/foundation.dart';

/// a mixin on [AbstractIO] that stores the loaded value for you
///
/// by itself this mixin isn't that powerful but it sets the stage for more useful
/// functionality with [ListStorage] and [MapStorage] to allow for iterable forms of
/// storage or [ValueAccess] for direct access to the value
mixin ValueStorage<W, R> on AbstractIO<W, R> {
  /// the stored data that was loaded
  R _data;

  /// writes [_data] using the [sendData] function
  Future<bool> write() async {
    return sendData(_data);
  }

  /// loads the value into [_data] using the [ioInterface]'s requestData function
  Future<void> load() async {
    return ioInterface.requestData();
  }

  @override
  @mustCallSuper
  void onDataRecieved(R data) {
    if (data == null) {
      return;
    }
    _data = data;
  }

  @override
  String toString() => _data.toString();

  void _notify() {
    if (_shouldNotify) {
      if (this is ListenerSupport) {
        (this as ListenerSupport).notifyListeners();
      } else if (this is ValueListenableSupport) {
        (this as ValueListenableSupport).notifyListeners();
      }
    }
  }

  bool _defaultShouldSave = true;
  bool _shouldNotify = true;
  bool _shouldSave = true;

  void _resetSave() {
    _shouldSave = _defaultShouldSave;
  }

  void _resetNotify() {
    _shouldNotify = true;
  }

  void _reset() {
    _resetSave();
    _resetNotify();
  }

  /// the default of whether or not this will save
  ///
  /// most functions that save have an optional parameter for saving with a default of true
  /// this value only affects those functions that don't such as the [] operator
  set shouldSave(bool shouldSave) {
    _defaultShouldSave = shouldSave;
    _shouldSave = shouldSave;
  }

  bool get shouldSave => _shouldSave;
}

/// a mixin that allows this to access the [_data] that is being stored
mixin ValueAccess<W, R> on ValueStorage<W, R> {
  /// the current value stored in this
  R get value {
    if (_data == null) {
      throw (StateError(
          "Current value is null and needs to be loaded or set before use"));
    }
    return _data;
  }

  /// sets the current value to [newVal]
  set value(R newVal) {
    if (_data is StorageAccess) {
      (_data as StorageAccess)?.storageReference = null;
      (newVal as StorageAccess).storageReference = this;
    }
    onDataRecieved(_data);
    _notify();
    if (_shouldSave) {
      write();
    }
  }

  @override
  @mustCallSuper
  void onDataRecieved(data) {
    super.onDataRecieved(data);
    if (_data is StorageAccess) {
      (_data as StorageAccess).storageReference = this;
    }
  }
}

/// gives [ValueStorage] an intial value
///
/// this value is set in the function [initialize] which is called in the initialization
/// of [AbstractIO]
///
/// the initial value will likely be overridden when the value is loaded
///
/// the [ListStorage] and [MapStorage] mixins initialize [_data] to and empty list
/// and an emtpy map respectively
mixin InitialValue<W, R> on ValueStorage<W, R> {
  R get initialValue;

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = initialValue;
  }
}

/// a mixin that makes the value storage [ValueListenable]
///
/// every time [onDataRecieved] is called the listeners are notified
///
/// additionally the [ListStorage] and [MapStorage] mixins notify listeners when
/// a value is added, removed and in some other cases as well
mixin ValueListenableSupport<W, R> on ValueStorage<W, R>
    implements ValueListenable<R> {
  List<VoidCallback> _listeners = [];

  /// notifies listeners that an update has occured
  void notifyListeners() {
    for (VoidCallback listener in _listeners) {
      listener();
    }
  }

  @override
  void addListener(listener) {
    if (listener == null) {
      return;
    }
    _listeners.add(listener);
  }

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

  /// the current value of this
  R get data => _data;
}

/// a mixin that allows this to call the [write] function for the
/// [ValueStorage] it is in
mixin StorageAccess {
  /// a reference to the [ValueStorage] this came from
  ValueStorage storageReference;

  /// saves this using the [ValueStorage] that stores it
  Future<bool> write() => storageReference.write();

  void notifyStorage() {
    storageReference._notify();
  }
}

/// adds the functionality of a list to this [ValueStorage]
///
/// automatically saves this list when a it is updated unless otherwise specified
///
/// automatically notifies listeners of an update if this has the [ListenerSupport] or
/// [ValueListenableSupport] mixin
mixin ListStorage<W, E> on ValueStorage<W, List<E>> implements List<E> {
  /// called when a value is added to the list
  ///
  /// if the element has the [StorageAccess] mixin its storage reference is set to this
  @protected
  void _addedToList(E element) {
    if (element == null) {
      return;
    }

    if (element is StorageAccess) {
      element.storageReference = this;
    }
  }

  /// called when a value is removed from the list
  ///
  /// if the element has the [StorageAccess] mixin its storage reference is set to null
  @protected
  void _removedFromList(E element) {
    if (element == null) {
      return;
    }
    if (element is StorageAccess) {
      element.storageReference = null;
    }
  }

  @override
  @mustCallSuper
  void onDataRecieved(List<E> data) {
    super.onDataRecieved(data);
    // if the values of the list have the StorageAccess mixin then their references
    // are set to this
    if (E is StorageAccess) {
      for (StorageAccess d in _data.cast<StorageAccess>()) {
        d.storageReference = this;
      }
    }
  }

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = <E>[];
  }

  @override
  E operator [](int index) => _data[index];

  @override
  void operator []=(int index, E newVal) async {
    _removedFromList(_data[index]);
    _addedToList(newVal);

    _data[index] = newVal;
    _notify();
    if (_shouldSave) {
      write();
    }
  }

  @override
  int get length {
    if (_data == null) {
      return 0;
    }
    return _data.length;
  }

  @override
  E get last => _data.last;

  @override
  E get first => _data.first;

  @override
  void add(E val, {bool save}) async {
    _addedToList(val);
    _data.add(val);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  bool remove(Object val, {bool save}) {
    if (val is E) {
      bool b = _data.remove(val);
      if (b) {
        _removedFromList(val);
      }
      _notify();
      if (save ?? _shouldSave) {
        write();
      }
      return b;
    }
    return false;
  }

  @override
  E removeAt(int index, {bool save}) {
    E t = _data.removeAt(index);
    _removedFromList(t);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
    return t;
  }

  @override
  void addAll(Iterable<E> values, {bool save}) async {
    if (values == null) {
      return;
    }
    for (E val in values) {
      _addedToList(val);
      _data.add(val);
    }
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  /// removes all the values and writes the list to the disk
  void removeAll(Iterable<E> values, {bool save}) {
    removeWhere((val) => values.contains(val), save: save);
  }

  /// if the two values are the same nothing happens
  /// otherwise the oldVal is removed and replaced
  /// with the newVal if the oldVal was in the list
  /// then writes the list
  ///
  /// returns whether or not the replace was a success
  bool replace(E oldVal, E newVal, {bool save}) {
    if (oldVal == null || newVal == null) {
      return false;
    }
    int index = _data.indexOf(oldVal);
    if (index == -1) {
      return false;
    }
    if (save == null) {
      _shouldSave = save;
    }
    this[index] = newVal;
    _resetSave();
    return true;
  }

  @override
  void setAll(int index, Iterable<E> iterable, {bool save}) async {
    int last = index + iterable.length;
    if (last > length) {
      last = length;
    }
    Iterator<E> iter = iterable.iterator;
    _shouldSave = false;
    _shouldNotify = false;
    for (int i = index; i < last; i++) {
      iter.moveNext();
      this[index] = iter.current;
    }
    _reset();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable,
      [int skipCount = 0, bool save]) async {
    for (E element in sublist(start, end)) {
      _removedFromList(element);
    }
    final int len = end - start;
    int index = 0;
    for (E element in iterable.skip(skipCount)) {
      if (len < index) {
        break;
      }
      index++;
      _addedToList(element);
    }

    _data.setRange(start, end, iterable, skipCount);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void shuffle([Random random, bool save]) async {
    _data.shuffle(random);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void clear({bool save}) {
    for (E val in _data) {
      _removedFromList(val);
    }
    _data.clear();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void fillRange(int start, int end, [E fillValue, bool save]) async {
    for (E val in sublist(start, end)) {
      _removedFromList(val);
    }
    _addedToList(fillValue);
    _data.fillRange(start, end, fillValue);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  set first(E value) {
    _removedFromList(_data.first);
    _addedToList(value);
    _data.first = value;
    _notify();
    if (_shouldSave) {
      write();
    }
  }

  @override
  set last(E value) {
    _removedFromList(_data.last);
    _addedToList(value);
    _data.last = value;
    _notify();
    if (_shouldSave) {
      write();
    }
  }

  @override
  void insert(int index, E element, {bool save}) async {
    _addedToList(element);
    _data.insert(index, element);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void insertAll(int index, Iterable<E> iterable, {bool save}) async {
    for (E val in iterable) {
      _addedToList(val);
    }
    _data.insertAll(index, iterable);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  set length(int newLength) {
    if (newLength < length) {
      for (int i = newLength; i < length; i++) {
        _removedFromList(this[i]);
      }
    }
    _data.length = length;
    _notify();
    if (_shouldSave) {
      write();
    }
  }

  @override
  E removeLast({bool save}) {
    E val = _data.removeLast();
    _removedFromList(val);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
    return val;
  }

  @override
  void removeRange(int start, int end, {bool save}) async {
    for (E val in sublist(start, end)) {
      _removedFromList(val);
    }
    _data.removeRange(start, end);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void removeWhere(bool Function(E element) test, {bool save}) async {
    for (E val in where(test)) {
      _removedFromList(val);
    }
    _data.removeWhere(test);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement,
      {bool save}) async {
    for (E val in sublist(start, end)) {
      _removedFromList(val);
    }
    for (E val in replacement) {
      _addedToList(val);
    }
    _data.replaceRange(start, end, replacement);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void retainWhere(bool Function(E element) test, {bool save}) async {
    for (E val in where((E element) => !test(element))) {
      _removedFromList(val);
    }
    _data.retainWhere(test);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  Iterator<E> get iterator => _data.iterator;

  @override
  bool any(bool Function(E element) test) => _data.any(test);

  @override
  Map<int, E> asMap() => _data.asMap();

  @override
  List<R> cast<R>() => _data.cast<R>();

  @override
  bool contains(Object element) => _data.contains(element);

  @override
  E elementAt(int index) => _data.elementAt(index);

  @override
  bool every(bool Function(E element) test) => _data.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) => _data.expand(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      _data.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      _data.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _data.followedBy(other);

  @override
  void forEach(void Function(E element) f) => _data.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => _data.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => _data.indexOf(element);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      _data.indexWhere(test, start);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  String join([String separator = ""]) => _data.join(separator);

  @override
  int lastIndexOf(E element, [int start]) => _data.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) =>
      _data.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) =>
      _data.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => _data.map(f);

  @override
  E reduce(E Function(E value, E element) combine) => _data.reduce(combine);

  @override
  Iterable<E> get reversed => _data.reversed;

  @override
  E get single => _data.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) =>
      _data.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => _data.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => _data.skipWhile(test);

  @override
  void sort([int Function(E a, E b) compare]) => _data.sort(compare);

  @override
  List<E> sublist(int start, [int end]) => _data.sublist(start, end);

  @override
  Iterable<E> take(int count) => _data.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => _data.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => _data.toList(growable: growable);

  @override
  Set<E> toSet() => _data.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => _data.where(test);

  @override
  Iterable<T> whereType<T>() => _data.whereType<T>();
}

/// adds the functionality of a Map to this [ValueStorage]
///
/// automatically saves this map when a value is updated unless otherwise specified
///
/// automatically notifies listeners of an update if this has the [ListenerSupport] or
/// [ValueListenableSupport] mixin
mixin MapStorage<W, K, V> on ValueStorage<W, Map<K, V>> implements Map<K, V> {
  /// called when a value is added to the map
  ///
  /// if the element has the [StorageAccess] mixin its storage reference is set to this
  void _addedVal(V val) {
    if (val == null) return;
    if (val is StorageAccess) val.storageReference = this;
  }

  /// called when a value is removed from the list
  ///
  /// if the element has the [StorageAccess] mixin its storage reference is set to null
  void _removedVal(V val) {
    if (val == null) return;
    if (val is StorageAccess) val.storageReference = null;
  }

  @override
  void onDataRecieved(Map data) {
    super.onDataRecieved(data);
    // if the value type has the StorageAccess mixin then the references of the
    //values are set to this
    if (V is StorageAccess) {
      for (StorageAccess val in data.values) {
        val.storageReference = this;
      }
    }
  }

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = <K, V>{};
  }

  @override
  V operator [](Object key) {
    return _data[key];
  }

  @override
  void operator []=(K key, V value) {
    _removedVal(_data[key]);
    _addedVal(value);
    _data[key] = value;
    if (_shouldSave) {
      write();
    }
    _notify();
  }

  @override
  void addAll(Map<K, V> other, {bool save}) {
    _shouldSave = false;
    _shouldNotify = false;

    for (K key in other.keys) {
      this[key] = other[key];
    }

    _reset();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries, {bool save}) {
    _shouldSave = false;
    _shouldNotify = false;

    for (MapEntry<K, V> entry in entries) {
      this[entry.key] = entry.value;
    }

    _reset();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void clear({bool save}) {
    for (V val in values) {
      _removedVal(val);
    }
    _data.clear();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent, {bool save}) {
    bool called = false;
    V val = _data.putIfAbsent(key, () {
      called = true;
      V val = ifAbsent();
      _addedVal(val);
      return val;
    });
    if (called) {
      _notify();
      if (save ?? _shouldSave) {
        write();
      }
    }
    return val;
  }

  @override
  V remove(Object key, {bool save}) {
    V val = _data.remove(key);
    _removedVal(val);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
    return val;
  }

  @override
  void removeWhere(bool Function(K, V) predicate, {bool save}) {
    bool removed = false;
    _shouldNotify = false;
    for (MapEntry<K, V> entry in entries) {
      if (predicate(entry.key, entry.value)) {
        removed = true;
        remove(entry.key, save: false);
      }
    }
    _reset();
    if (removed) {
      _notify();
      if (save ?? _shouldSave) {
        write();
      }
    }
  }

  @override
  V update(K key, V Function(V value) update,
      {V Function() ifAbsent, bool save}) {
    V data = _data.update(key, update, ifAbsent: ifAbsent);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
    return data;
  }

  @override
  void updateAll(V Function(K, V) update, {bool save}) {
    _data.updateAll(update);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  void forEach(void Function(K, V) f, {bool save, bool shouldNotify}) {
    _data.forEach(f);
    if (shouldNotify == null) {
      _notify();
    } else if (shouldNotify) {
      bool t = _shouldNotify;
      _shouldNotify = true;
      _notify();
      _shouldNotify = t;
    }
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    return _data.cast<RK, RV>();
  }

  @override
  bool containsKey(Object key) {
    return _data.containsKey(key);
  }

  @override
  bool containsValue(Object value) {
    return _data.containsValue(value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries => _data.entries;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable<K> get keys => _data.keys;

  @override
  int get length => _data.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K, V) f) {
    return _data.map(f);
  }

  @override
  Iterable<V> get values => _data.values;
}

/// adds some optimizations to the [MapStorage] mixin if the data is stored as a map
/// that can have values accessed independently using [ExternalMapIO]
///
/// this allows the user to modify and save specific entries rather than
/// saving the whole map when a value is changed
mixin ExternalMapOptimizations<KW, VW, KR, VR>
    on ExternalMapIO<KW, VW, KR, VR>, MapStorage<Map<KW, VW>, KR, VR> {
  @override
  void operator []=(KR key, VR value) {
    _removedVal(_data[key]);
    _addedVal(value);
    _data[key] = value;
    if (_shouldSave) {
      setEntry(key, value);
    }
    _notify();
  }

  @override
  void addAll(Map<KR, VR> other, {bool save}) {
    if (save != null) {
      _shouldSave = save;
    }
    _shouldNotify = false;
    for (KR key in other.keys) {
      this[key] = other[key];
    }
    _reset();
    _notify();
  }

  @override
  void addEntries(Iterable<MapEntry<KR, VR>> entries, {bool save}) {
    if (save != null) {
      _shouldSave = save;
    }
    _shouldNotify = false;
    for (MapEntry<KR, VR> entry in entries) {
      this[entry.key] = entry.value;
    }
    _reset();
    _notify();
  }

  @override
  Future<KR> addEntry(value) async {
    KR key = await super.addEntry(value);
    _data[key] = value;
    return key;
  }

  @override
  void clear({bool save}) {
    bool s = save ?? _shouldSave;
    for (MapEntry<KR, VR> entry in entries) {
      if (s) {
        deleteEntry(entry.key);
      }
      _removedVal(entry.value);
    }
    _data.clear();
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  @override
  VR putIfAbsent(KR key, VR Function() ifAbsent, {bool save}) {
    bool called = false;
    VR val = _data.putIfAbsent(key, () {
      called = true;
      VR val = ifAbsent();
      _addedVal(val);
      return val;
    });
    if (called) {
      _notify();
      if (save ?? _shouldSave) {
        setEntry(key, val);
      }
    }
    return val;
  }

  @override
  VR remove(Object key, {bool save}) {
    VR val = _data.remove(key);
    _removedVal(val);
    _notify();
    if (save ?? _shouldSave) {
      deleteEntry(key);
    }
    return val;
  }

  @override
  void removeWhere(bool Function(KR, VR) predicate, {bool save}) {
    bool removed = false;
    bool s = save ?? _shouldSave;
    _shouldNotify = false;
    for (MapEntry<KR, VR> entry in entries) {
      if (predicate(entry.key, entry.value)) {
        removed = true;
        remove(entry.key, save: s);
      }
    }
    _resetNotify();
    if (removed) {
      _notify();
    }
  }

  @override
  VR update(KR key, VR Function(VR value) update,
      {VR Function() ifAbsent, bool save, bool lock = false}) {
    if (lock && (save ?? _shouldSave)) {
      VR val;
      lockAndUpdateEntry(key, (value) {
        if (value == null) {
          val = ifAbsent();
        } else {
          val = update(value);
        }
        return val;
      }).then((value) {
        _data[key] = value;
        _notify();
      });
      return val;
    }
    VR data = _data.update(key, update, ifAbsent: ifAbsent);
    if (save ?? _shouldSave) {
      setEntry(key, data);
    }
    _notify();
    return data;
  }

  @override
  void updateAll(VR Function(KR, VR) update, {bool save, bool lock = false}) {
    if ((save ?? _shouldSave) && lock) {
      lockAndUpdate((newData) {
        newData.updateAll(update);
        return newData;
      }).then((value) {
        _data.addAll(value);
        _notify();
      });
      return;
    }
    _data.updateAll(update);
    _notify();
    if (save ?? _shouldSave) {
      write();
    }
  }

  /// writes the entry with the given [key]
  Future<bool> writeEntry(KR key) {
    return setEntry(key, _data[key]);
  }
}
