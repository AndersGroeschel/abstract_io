
import 'abstract_base.dart';

/// adds the functionality to [lockAndUpdate] data,
/// this is often nessecary functionality when storing data off device to avoid race conditions
mixin Lock<W> on IOInterface<W>{
  /// locks the data where it is being stored and updates it
  ///
  /// the protocol [lockAndUpdate] should follow is
  ///
  /// 1) lock the data
  ///
  /// 2) request new data
  ///
  /// 3) translate data of type W into type R using the [translator]
  ///
  /// 4) [update] the data
  ///
  /// 5) translate the update data of type R back into type W
  ///
  /// 6) write the data and unlock
  Future<R> lockAndUpdate<R>(R Function(R newData) update,
      {Translator<W, R> translator});

}

mixin LockEntry<KW,VW> on MapIOInterface<KW,VW>{

  /// lock and update a specific entry with the given [key]
  ///
  /// should follow the same general protocol as [lockAndUpdate]
  Future<V> lockAndUpdateEntry<V>(KW key, V Function(V newData) update,
      {Translator<VW, V> valueTranslator});

}

mixin LockMap<KW, VW> on MapIOInterface<KW,VW> implements Lock<Map<KW,VW>>, LockEntry<KW,VW>{}


abstract class LockableMapIO<KW, VW, KR, VR> extends MapIO<KW,VW, KR, VR> implements EntryLockableMapIO<KW, VW, KR, VR>, LockableIO<Map<KW,VW>, Map<KR,VR>>{
  
  LockableMapIO(
    LockMap<KW, VW> ioInterface,
    {
      Translator<KW, KR> keyTranslator,
      Translator<VW, VR> valueTranslator
    }
  ) : super(
    ioInterface,
    keyTranslator: keyTranslator,
    valueTranslator: valueTranslator
  );

  /// locks the entry with the given [key] and updates it using the [update] function
  ///
  /// returns the updated value in a future
  Future<VR> lockAndUpdateEntry(KR key, VR Function(VR newData) update) {
    return (ioInterface as LockMap).lockAndUpdateEntry<VR>(
        keyTranslator.translateReadable(key), update,
        valueTranslator: valueTranslator);
  }

  /// [lockAndUpdate] will lock the server side data and allow you to update it with
  /// the [update] function
  ///
  /// the functionality of this is handled by the [ioInterface] which must be an [LockableIOInterface]
  Future<Map<KR,VR>> lockAndUpdate(Map<KR,VR> Function(Map<KR,VR> newData) update) {
    return (ioInterface as LockMap)
        .lockAndUpdate<Map<KR,VR>>(update, translator: translator);
  }

}


abstract class EntryLockableMapIO<KW, VW, KR, VR> extends MapIO<KW,VW, KR, VR>{

  EntryLockableMapIO(
    LockEntry<KW, VW> ioInterface,
    {
      Translator<KW, KR> keyTranslator,
      Translator<VW, VR> valueTranslator
    }
  ) : super(
    ioInterface,
    keyTranslator: keyTranslator,
    valueTranslator: valueTranslator
  );

  /// locks the entry with the given [key] and updates it using the [update] function
  ///
  /// returns the updated value in a future
  Future<VR> lockAndUpdateEntry(KR key, VR Function(VR newData) update) {
    return (ioInterface as LockEntry).lockAndUpdateEntry<VR>(
        keyTranslator.translateReadable(key), update,
        valueTranslator: valueTranslator);
  }
  
  
}


/// [LockableIO] is an extension of [AbstractIO] to provide the function
/// of [lockAndUpdate] so that data can be locked and then updated, this
/// class requires that the [ioInterface] is an [LockableIOInterface]
///
/// [lockAndUpdate] is much needed functionality when working with data that is
/// stored off device and modified by multiple devices because without it is possible
/// a data race could occur
///
/// for more information about writing and reading data visit the parent class [AbstractIO]
abstract class LockableIO<W, R> extends AbstractIO<W, R> {
  LockableIO(
    Lock<W> ioInterface, {
    Translator<W, R> translator,
  }) : super(ioInterface, translator: translator);

  /// [lockAndUpdate] will lock the server side data and allow you to update it with
  /// the [update] function
  ///
  /// the functionality of this is handled by the [ioInterface] which must be an [LockableIOInterface]
  Future<R> lockAndUpdate(R Function(R newData) update) {
    return (ioInterface as Lock)
        .lockAndUpdate<R>(update, translator: translator);
  }
}


