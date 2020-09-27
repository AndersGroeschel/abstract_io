import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'abstract_base.dart';
import 'locking.dart';

/// could be broken by race conditions, a way to fix this would be to store the key within the data
/// and use that key to add to map
mixin EntryStorage<KW,VW, KR,VR> on AbstractDirectory<KW,VW, KR,VR> implements Map<KR,VR>{

  VR _temp;

  final Map<KR,VR> _map = {};

  bool _save = true;


  Future<void> loadEntry(KR key) async {
    await ioInterface.requestEntry(keyTranslator.translateReadable(key));
    _map[key] = _temp;
  }  

  Future<bool> writeEntry(KR key) async {
    return storeEntry(key, this[key]);
  }

  @override
  void onDataRecieved(VR data) {
    _temp = data;
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    return _map.cast<RK, RV>();
  }

  @override
  bool containsKey(Object key) {
    return _map.containsKey(key);
  }

  @override
  bool containsValue(Object value) {
    return _map.containsValue(value);
  }

  @override
  Iterable<MapEntry<KR, VR>> get entries => _map.entries;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;

  @override
  Iterable<KR> get keys => _map.keys;

  @override
  int get length => _map.length;

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(KR, VR) f) {
    return _map.map(f);
  }

  @override
  Iterable<VR> get values => _map.values;

  /// Applies [f] to each key/value pair of the map.
  /// 
  /// Calling f must not add or remove keys from the map.
  /// 
  /// Copied from [Map].
  /// 
  /// note this will not save values consider using [updateAll] instead if you want values saved
  @override
  void forEach(void Function(KR key, VR value) f) => _map.forEach(f);


  @override
  VR operator [](Object key) => _map[key];

  @override
  void operator []=(KR key, VR value) {
    _map[key] = value;
    if(_save){
      storeEntry(key, value);
    }
  }

  @override
  Future<void> addAll(Map<KR,VR> other, {bool save}) async {
    _map.addAll(other);
    if(save??_save){
      await Future.wait([
        for(MapEntry<KR,VR> entry in other.entries)
          storeEntry(entry.key, entry.value),
      ]);
    }
  }

  @override
  Future<void> addEntries(Iterable<MapEntry<KR, VR>> newEntries,{bool save}) async {
    _map.addEntries(newEntries);
    if(save??_save){
      await Future.wait([
        for(MapEntry<KR,VR> entry in newEntries)
          storeEntry(entry.key, entry.value),
      ]);
    }
  }

  @override
  Future<void> clear({bool save}) async {
    if(save??_save){
      await Future.wait([
        for(KR key in _map.keys)
          deleteEntry(key),
      ]);
    }
    _map.clear();
  }

  @override
  VR putIfAbsent(KR key, VR Function() ifAbsent, {bool save}) {
    return _map.putIfAbsent(key, (){
      VR val = ifAbsent();
      if(save?? _save){
        storeEntry(key, val);
      }
      return val;
    });
  }

  @override
  VR remove(Object key, {bool save}) {
    if(key is KR){
      if(save??_save){
        deleteEntry(key);
      }
      return _map.remove(key);
    }
    return null;
  }

  @override
  void removeWhere(bool Function(KR key, VR value) predicate, {bool save}) {


    Set<KR> toRemove = _map.entries.where((element) => predicate(element.key,element.value)).map((e) => e.key).toSet();

    _map.removeWhere((key, value) => toRemove.contains(toRemove));

    if(save??_save){
      Future.wait([
        for(KR key in toRemove)
          deleteEntry(key)
      ]);
    }
  }

  @override
  VR update(KR key , VR Function(VR value) update, {VR Function() ifAbsent, bool save}) {
    VR val = _map.update(key, update, ifAbsent: ifAbsent);
    if(save??_save){
      storeEntry(key,val);
    }
    return val;
  }

  @override
  void updateAll(VR Function(KR key, VR value) update, {bool save}) {
    for(MapEntry<KR,VR> entry in _map.entries){
      _map[entry.key] = update(entry.key,entry.value);
      if(save??_save){
        writeEntry(entry.key);
      }
    }
  }
}

mixin EntryStorageLock<KW, VW, KR, VR> on AbstractLockableDirectory<KW, VW, KR, VR>, EntryStorage<KW,VW, KR,VR>{

  @override
  VR update(KR key, VR Function(VR value) update,
      {VR Function() ifAbsent, bool save, bool lock = false}) {

    if (lock && (save ?? _save)) {
      VR val;
      lockAndUpdateEntry(key, (value) {
        if (value == null) {
          val = ifAbsent();
        } else {
          val = update(value);
        }
        return val;
      }).then((value) {
        _map[key] = value;
        if(this is EntryListenable){
          (this as EntryListenable).notifyListeners();
        }
      });
      return val;
    }

    VR data = _map.update(key, update, ifAbsent: ifAbsent);
    if (save ?? _save) {
      storeEntry(key, data);
    }
    return data;
  }

  ///Updates all values.
  ///
  ///Iterates over all entries in the map and updates them with the result of invoking [update].
  ///
  ///Copied from Map.
  ///
  /// this function assumes that updating an entry does not depened on other entries 
  /// when the lock is activiated
  @override
  Future<void> updateAll(Function(KR key, VR value) update, {bool save, bool lock = false}) async {
    if(lock && (save?? _save)){
      await Future.wait([
        for(KR key in _map.keys)
          lockAndUpdateEntry(key, (newData) => update(key,newData)).then((value) => _map[key] = value)
      ]);
    }
    if(!lock){
      super.updateAll(update, save: save);
    }
  }

}


mixin KeyContainer<K>{

  K get key;

}

mixin KeyContainerFunctionality<KW,VW, KR,VR extends KeyContainer> on EntryStorage<KW,VW, KR,VR>{


  Future<void> loadEntry(KR key) async {
    await ioInterface.requestEntry(keyTranslator.translateReadable(key));
  } 

  @override
  void onDataRecieved(VR data) {
    _map[data.key] = data;
  }


}


/// notifies listeners when entries change via the standard map functions
mixin EntryListenable<KW,VW, KR,VR> on EntryStorage<KW,VW, KR,VR> implements ValueListenable<Map<KR,VR>>{

  final List<VoidCallback> _listeners = [];

  Map<KR,VR> get data => _map;

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


  @override
  void operator []=(KR key, VR value) {
    super[key] = value;
    notifyListeners();
  }

  @override
  Future<void> addAll(Map<KR,VR> other, {bool save}) async {
    super.addAll(other, save: save);
    notifyListeners();
  }

  @override
  Future<void> addEntries(Iterable<MapEntry<KR, VR>> newEntries,{bool save}) async {
    super.addEntries(newEntries, save: save);
    notifyListeners();
  }

  @override
  Future<void> clear({bool save}) async {
    super.clear(save: save);
    notifyListeners();
  }

  @override
  VR putIfAbsent(KR key, VR Function() ifAbsent, {bool save}) {
    bool newval = false;
    VR val = super.putIfAbsent(key, (){
      newval = true;
      return ifAbsent();
    }, save: save);

    if(newval){
      notifyListeners();
    }
    return val;
  }

  @override
  VR remove(Object key, {bool save}) {
    bool notify = this.containsKey(key);
    VR val = super.remove(key, save: save);
    if(notify){
      notifyListeners();
    }
    return val;
  }

  @override
  void removeWhere(bool Function(KR key, VR value) predicate, {bool save}) {
    super.removeWhere(predicate, save: save);
    notifyListeners();
  }

  @override
  VR update(KR key , VR Function(VR value) update, {VR Function() ifAbsent, bool save}) {
    VR val = super.update(key, update, ifAbsent: ifAbsent, save: save);
    notifyListeners();
    return val;
  }

  @override
  void updateAll(VR Function(KR key, VR value) update, {bool save}) {
    super.updateAll(update, save: save);
    notifyListeners();
  }

}


