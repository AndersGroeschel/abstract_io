import 'package:abstract_io/abstract_io.dart';
import 'package:flutter/foundation.dart';

/// [MapIO] is meant to be the [AbstractIO] for when the data on the server side
/// is stored in some form of a map
///
/// it provides additional functionality to access and modify specific entries
///
/// [MapIO] is best used with [MapStorage] and [MapOptimizations]
/// to take full advantage of seperate entry storage
abstract class MapIO<KW, VW, KR, VR>
    extends AbstractIO<Map<KW, VW>, Map<KR, VR>> {
  /// the translator for the key from the key writable (KW) and the key readable (KR)
  final Translator<KW, KR> keyTranslator;

  /// the translator for the value from the value writable (VW) and the value readable (VR)
  final Translator<VW, VR> valueTranslator;

  final MapIOInterface<KW, VW> ioInterface;

  MapIO(
    this.ioInterface,
    {
      Translator<KW, KR> keyTranslator, 
      Translator<VW, VR> valueTranslator
    }
  ): 
    this.keyTranslator = keyTranslator?? CastingTranslator<KW, KR>(),
    this.valueTranslator = valueTranslator?? CastingTranslator<VW, VR>(),
    super(
      ioInterface,
      translator: TranslatorMap(
          keyTranslator ?? CastingTranslator<KW, KR>(),
          valueTranslator ?? CastingTranslator<VW, VR>()),
    );


  @override
  @mustCallSuper
  void initialize() {
    ioInterface.onEntryRecieved = (KW key, VW value){
      onEntryRecieved(
        keyTranslator.translateWritable(key), 
        valueTranslator.translateWritable(value)
      );
    };
    ioInterface.entryLoad = true;
    super.initialize();
  }

  void onEntryRecieved(KR key, VR value);

  /// creates a new entry with the given [value] the associated key is returned
  ///
  /// if you want to create a new entry with a specific key [setEntry] should be used instead
  ///
  /// the core functionality is handled by the [ioInterface]
  Future<KR> addEntry(VR value) async {
    return keyTranslator.translateWritable(
      await ioInterface.addEntry(valueTranslator.translateReadable(value))
    );
  }

  /// delets the entry with the given [key]
  ///
  /// returns whether or not the deletion was successful,
  /// a value of false does not necessarily mean the data was not deleted
  Future<bool> deleteEntry(KR key) {
    return ioInterface.deleteEntry(keyTranslator.translateReadable(key));
  }

  /// sets the entry with the given [key] to the given [value] and
  /// returns whether or not the setting was successful
  ///
  /// if the entry with [key] does not previously exist then it is created
  Future<bool> setEntry(KR key, VR value) {
    return ioInterface.setEntry(
      keyTranslator.translateReadable(key),
      valueTranslator.translateReadable(value)
    );
  }

  
}


abstract class MapIOInterface<KW, VW>
    extends IOInterface<Map<KW, VW>> {


  /// if true this should call [onEntryRecieved] for every entry during [requestData]
  /// rather than loading all data at once and calling [onDataRecieved]
  /// 
  /// by default [entryLoad] is false but will be set to true if this is used in [MapIO]
  bool entryLoad = false;


  /// this funtion is called whenever this receives a specific data entry
  ///
  /// DO NOT set it to a value or overide it that is handled by a [MapIO] object
  void Function(KW key , VW value ) onEntryRecieved;


  /// delete the entry for the [key]
  ///
  /// returns whether or not the deletion was successful,
  /// a value of false does not necessarily mean the data was not deleted
  Future<bool> deleteEntry(KW key);

  /// sets the entry with the given [key] to the given [value]
  ///
  /// if the entry does not exist beforehand it is created
  ///
  /// returns whether or not it was succeful in adding
  Future<bool> setEntry(KW key, VW value);

  /// create a new entry with the given [value] and return its associated key
  Future<KW> addEntry(VW value);

  Future<void> requestEntry(KW key);

}

