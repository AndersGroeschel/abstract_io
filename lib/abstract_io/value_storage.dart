import 'dart:math';
import 'package:flutter/foundation.dart';

import 'abstract_base.dart';
import 'additional_functionality.dart';

//TODO Documentation

/// a mixin on [AbstractIO] that stores the loaded value for you
/// 
/// 
mixin ValueStorage<W,R> on AbstractIO<W,R>{
  R _data;

  Future<bool> write() async {
    return sendData(_data);
  }

  Future<void> load() async {
    return ioInterface.requestData();
  }

  @override
  void onDataRecieved(R data) {
    _data = data;
    if(_data is StorageAccess){
      (_data as StorageAccess)._io = this;
    }else if(_data is Iterable<StorageAccess>){
      for(StorageAccess d in _data){
        d._io = this;
      }
    }else if(_data is Map){
      try {
        for(StorageAccess d in (_data as Map).values){
          d._io = this;
        }
      } catch (e) {
      }
      try {
        for(StorageAccess d in (_data as Map).keys){
          d._io = this;
        }
      } catch (e) {
      }
    }
  }

}



mixin ValueAccess<W,R> on ValueStorage<W,R>{

  /// the current value stored in this
  R get value{
    if(_data == null){
      throw(StateError("Current value is null and needs to be loaded or set before use"));
    }
    return _data;
  }

  set value(R newVal){
    if(_data is StorageAccess){
      (_data as StorageAccess)._io = null;
      (newVal as StorageAccess)._io = this;
    }
    onDataRecieved(_data);
    write();
  }
}

mixin InitialValue<W,R> on ValueStorage<W,R>{
  R get initialValue;

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = initialValue;
  }
}

mixin ValueListenableSupport<W,R> on ValueStorage<W,R> implements ValueListenable<R>{

  List<VoidCallback> _listeners = [];

  void notifyListeners(){
    for(VoidCallback listener in _listeners){
      listener();
    }
  }

  @override
  void addListener(listener) {
    if(listener == null){
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

  R get data => _data;
}





/// a mixin that allows this to call the [write] function for the 
/// [ValueStorage] it is in
mixin StorageAccess{

  /// a reference to the [ValueStorage] this came from 
  /// 
  /// it is not gaurenteed to be non-null unless this was read 
  /// using an [ValueStorage] with the proper functionality
  ValueStorage _io;

  /// saves this using the [ValueStorage] that stores it
  Future<bool> write() => _io.write();
}






mixin ListStorage<W,E> on ValueStorage<W,List<E>> implements List<E>{


  bool _shouldNotify = true;
  void _notify(){
    if(_shouldNotify){
      if(this is ListenerSupport){
        (this as ListenerSupport).notifyListeners();
      }else if(this is ValueListenableSupport){
        (this as ValueListenableSupport).notifyListeners();
      }
    }
  }

  bool _shouldSave = true;

  @protected
  void _addedToList(E element){
    if(element == null)
      return;

    if(element is StorageAccess)
      element._io = this;
  }

  @protected
  void _removedFromList(E element){
    if(element == null)
      return;
    if(element is StorageAccess)
      element._io = null;
  }

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = <E>[];
  }
  
  @override
  E operator [] (int index) => _data[index];
  
  @override
  void operator []= (int index, E newVal) async {
    _removedFromList(_data[index]);
    _addedToList(newVal);

    _data[index] = newVal;
    _notify();
    if(_shouldSave){
      write();
    }
  }

  
  @override
  int get length{
    if(_data == null){
      return 0;
    }
    return _data.length;
  }
  
  @override
  E get last => _data.last;
  
  @override
  E get first => _data.first;


  
  @override
  void add(E val, {bool save = true}) async {
    _addedToList(val);
    _data.add(val);
    if(save){
      write();
    }
    _notify();
  }
  
  @override
  bool remove(Object val, {bool save = true}){
    if(val is E){
      bool b = _data.remove(val);
      if(b){
        _removedFromList(val);
      }
      if(save){
        write();
      }
      _notify();
      return b;
    }
    return false; 
  }
  
  @override
  E removeAt(int index, {bool save = true}){
    E t = _data.removeAt(index);
    _removedFromList(t);
    if(save){
      write();
    }
    _notify();
    return t;
  }
  
  @override
  void addAll(Iterable<E> values, {bool save = true}) async {
    if(values == null){
      return;
    }
    for(E val in values){
      _addedToList(val);
      _data.add(val);
    }
    if(save){
      write();
    }
    _notify();
  }

  /// removes all the values and writes the list to the disk
  void removeAll(Iterable<E> values, {bool save = true}){
    removeWhere((val) => values.contains(val), save: save);
  }


  /// if the two values are the same nothing happens
  /// otherwise the oldVal is removed and replaced 
  /// with the newVal if the oldVal was in the list
  /// then writes the list
  /// 
  /// returns whether or not the replace was a success
  bool replace(E oldVal, E newVal, {bool save = true}){
    if(oldVal == null || newVal == null){
      return false;
    }
    int index = _data.indexOf(oldVal); 
    if(index == -1){
      return false;
    }
    _shouldSave = save;
    this[index] = newVal;
    _shouldSave = true;
    return true;
  }

  @override
  void setAll(int index, Iterable<E> iterable, {bool save = true}) async {
    int last = index + iterable.length;
    if(last > length){
      last = length;
    }
    Iterator<E> iter = iterable.iterator;
    _shouldSave = false;
    _shouldNotify = false;
    for(int i = index; i < last; i++){
      iter.moveNext();
      this[index] = iter.current;
    }
    _shouldSave = true;
    _shouldNotify = true;
    if(save){
      write();
    }
    _notify();
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0, bool save = true]) async {
    for(E element in sublist(start, end)){
      _removedFromList(element);
    }
    final int len = end - start;
    int index = 0;
    for(E element in iterable.skip(skipCount)){
      if(len < index){
        break;
      }
      index++;
      _addedToList(element);
    }

    _data.setRange(start, end, iterable, skipCount);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void shuffle([Random random, bool save = true]) async {
    _data.shuffle(random);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void clear({bool save = true}) {
    for(E val in _data){
      _removedFromList(val);
    }
    _data.clear();
    if(save){
      write();
    }
    _notify();
  }

  @override
  void fillRange(int start, int end, [E fillValue, bool save = true]) async {
    for(E val in sublist(start, end)){
      _removedFromList(val);
    }
    _addedToList(fillValue);
    _data.fillRange(start, end, fillValue);
    if(save){
      write();
    }
    _notify();
  }

  @override
  set first(E value) {
    _removedFromList(_data.first);
    _addedToList(value);
    _data.first = value;
    if(_shouldSave){
      write();
    }
    _notify();
  }

  @override
  set last(E value) {
    _removedFromList(_data.last);
    _addedToList(value);
    _data.last = value;
    if(_shouldSave){
      write();
    }
    _notify();
  }

  @override
  void insert(int index, E element, {bool save = true}) async {
    _addedToList(element);
    _data.insert(index, element);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void insertAll(int index, Iterable<E> iterable, {bool save = true}) async {
    for(E val in iterable){
      _addedToList(val);
    }
    _data.insertAll(index, iterable);
    if(save){
      write();
    }
    _notify();
  }

  @override
  set length(int newLength) {
    if(newLength < length){
      for(int i = newLength; i < length; i++){
        _removedFromList(this[i]);
      }
    }
    _data.length = length;
    if(_shouldSave){
      write();
    }
    _notify();
  }

  @override
  E removeLast({bool save = true}){
    E val = _data.removeLast();
    _removedFromList(val);
    if(save){
      write();
    }
    _notify();
    return val;
  }

  @override
  void removeRange(int start, int end, {bool save = true}) async {
    for(E val in sublist(start, end)){
      _removedFromList(val);
    }
    _data.removeRange(start, end);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void removeWhere(bool Function(E element) test, {bool save = true}) async {
    for(E val in where(test)){
      _removedFromList(val);
    }
    _data.removeWhere(test);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement, {bool save = true}) async {
    for(E val in sublist(start, end)){
      _removedFromList(val);
    }
    for(E val in replacement){
      _addedToList(val);
    }
    _data.replaceRange(start, end, replacement);
    if(save){
      write();
    }
    _notify();
  }

  @override
  void retainWhere(bool Function(E element) test, {bool save = true}) async {
    for(E val in where((E element) => !test(element))){
      _removedFromList(val);
    }
    _data.retainWhere(test);
    if(save){
      write();
    }
    _notify();
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
  E firstWhere(bool Function(E element) test, {E Function() orElse}) => _data.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) => _data.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _data.followedBy(other);

  @override
  void forEach(void Function(E element) f) => _data.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => _data.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => _data.indexOf(element);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) => _data.indexWhere(test, start);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  String join([String separator = ""]) => _data.join(separator);

  @override
  int lastIndexOf(E element, [int start]) => _data.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) => _data.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) => _data.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => _data.map(f);

  @override
  E reduce(E Function(E value, E element) combine) => _data.reduce(combine);

  @override
  Iterable<E> get reversed => _data.reversed;

  @override
  E get single => _data.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) => _data.singleWhere(test, orElse: orElse);

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


mixin MapStorage<W,K,V> on ValueStorage<W,Map<K,V>>  implements Map<K,V>{

  bool _shouldNotify = true;
  void _notify(){
    if(_shouldNotify){
      if(this is ListenerSupport){
        (this as ListenerSupport).notifyListeners();
      }else if(this is ValueListenableSupport){
        (this as ValueListenableSupport).notifyListeners();
      }
    }
  }

  bool _shouldSave = true;

  void _addedVal(V val){
    if(val == null)
      return;
    if(val is StorageAccess)
      val._io = this;
  }

  void _removedVal(V val){
    if(val == null)
      return;
    if(val is StorageAccess)
      val._io = null;
  }

  @override
  @mustCallSuper
  void initialize() {
    super.initialize();
    _data = <K,V>{};
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
    if(_shouldSave){
      write();
    }
    _notify();
  }

  @override
  void addAll(Map<K,V> other, {bool save = true}) {
    _shouldSave = false;
    _shouldNotify = false;

    for(K key in other.keys){
      this[key] = other[key];
    }

    _shouldNotify = true;
    _notify();

    _shouldSave = true;
    if(save){
      write();
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K,V>> entries, {bool save = true}) {
    _shouldSave = false;
    _shouldNotify = false;

    for(MapEntry<K,V> entry in entries){
      this[entry.key] = entry.value;
    }

    _shouldNotify = true;
    _notify();

    _shouldSave = true;
    if(save){
      write();
    }
  }

  @override
  void clear({bool save = true}) {
    for(V val in values){
      _removedVal(val);
    }
    _data.clear();
    _notify();
    if(save){
      write();
    }
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent, {bool save = true}) {
    bool called = false;
    V val = _data.putIfAbsent(key, (){
      called = true;
      V val = ifAbsent();
      _addedVal(val);
      return val;
    });
    if(called){
      _notify();
      if(save){
        write();
      }
    }
    return val;
  }

  @override
  V remove(Object key, {bool save = true}) {
    V val = _data.remove(key);
    _removedVal(val);
    _notify();
    if(save){
      write();
    }
    return val;
  }

  @override
  void removeWhere(bool Function(K,V) predicate, {bool save = true}) {
    bool removed = false;
    _shouldNotify = false;
    for(MapEntry<K,V> entry in entries){
      if(predicate(entry.key, entry.value)){
        removed = true;
        remove(entry.key, save: false);
      }
    }
    _shouldNotify = true;
    if(removed){
      _notify();
      if(save){
        write();
      }
    }
    
  }

  @override
  V update(K key, V Function(V value) update,{V Function() ifAbsent, bool save = true}) {
    V data = _data.update(key, update, ifAbsent: ifAbsent);
    if(save){
      write();
    }
    _notify();
    return data;
  }

  @override
  void updateAll(V Function(K,V) update, {bool save = true}) {
    _data.updateAll(update);
    if(save){
      write();
    }
    _notify();
  }






  @override
  Map<RK, RV> cast<RK, RV>() {
    return _data.cast<RK,RV>();
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
  void forEach(void Function(K,V) f) {
    _data.forEach(f);
  }

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Iterable<K> get keys => _data.keys;

  @override
  int get length => _data.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2,V2> Function(K,V) f) {
    return _data.map(f);
  }

  @override
  Iterable<V> get values => _data.values;

}


mixin ExternalMapOptimizations<KW,VW, KR,VR> on ExternalMapIO<KW,VW, KR,VR>, MapStorage<Map<KW,VW>, KR,VR>{

  @override
  void operator []=(KR key, VR value) {
    _removedVal(_data[key]);
    _addedVal(value);
    _data[key] = value;
    if(_shouldSave){
      setEntry(key, value);
    }
    _notify();
  }

  @override
  void addAll(Map<KR,VR> other, {bool save = true}) {
    _shouldSave = save;
    _shouldNotify = false;
    for(KR key in other.keys){
      this[key] = other[key];
    }
    _shouldNotify = true;
    _notify();
  }

  @override
  void addEntries(Iterable<MapEntry<KR,VR>> entries, {bool save = true}) {
    _shouldSave = save;
    _shouldNotify = false;
    for(MapEntry<KR,VR> entry in entries){
      this[entry.key] = entry.value;
    }
    _shouldNotify = true;
    _notify();
  }

  @override
  Future<KR> addEntry(value) async {
    KR key = await super.addEntry(value);
    _data[key] = value;
    return key;
  }

  @override
  void clear({bool save = true}) {
    for(MapEntry<KR,VR> entry in entries){
      if(save){
        deleteEntry(entry.key);
      }
      _removedVal(entry.value);
    }
    _data.clear();
    _notify();
  }

  @override
  VR putIfAbsent(KR key, VR Function() ifAbsent, {bool save = true}) {
    bool called = false;
    VR val = _data.putIfAbsent(key, (){
      called = true;
      VR val = ifAbsent();
      _addedVal(val);
      return val;
    });
    if(called){
      _notify();
      if(save){
        setEntry(key, val);
      }
    }
    return val;
  }

  @override
  VR remove(Object key, {bool save = true}) {
    VR val = _data.remove(key);
    _removedVal(val);
    _notify();
    if(save){
      deleteEntry(key);
    }
    return val;
  }

  @override
  void removeWhere(bool Function(KR,VR) predicate, {bool save = true}) {
    bool removed = false;
    _shouldNotify = false;
    for(MapEntry<KR,VR> entry in entries){
      if(predicate(entry.key, entry.value)){
        removed = true;
        remove(entry.key, save: save);
      }
    }
    _shouldNotify = true;
    if(removed){
      _notify();
    }
    
  }

  @override
  VR update(KR key, VR Function(VR value) update,{VR Function() ifAbsent, bool save = true, bool lock = false}) {
    if(lock && save){
      VR val;
      lockAndUpdateEntry(key, (value){
        if(value == null){
          val = ifAbsent();
        }else{
          val = update(value);
        }
        return val;
      }).then((value){
        _data[key] = value;
      });
      return val;
    }
    VR data = _data.update(key, update, ifAbsent: ifAbsent);
    if(save){
      setEntry(key, data);
    }
    _notify();
    return data;
  }

  @override
  void updateAll(VR Function(KR,VR) update, {bool save = true, bool lock = false}) {
    if(save && lock){
      lockAndUpdate((newData){
        newData.updateAll(update);
        return newData;
      }).then((value){
        _data.addAll(value);
      });
      return;
    }
    _data.updateAll(update);
    if(save){
      write();
    }
    _notify();
  }

  Future<bool> saveEntry(KR key){
    return setEntry(key, _data[key]);
  }

}










