import 'package:abstract_io/abstract_io.dart';
import 'package:flutter/foundation.dart';

/// the base class for transfering data in and out of the program
///
/// W is meant to be the type the data is stored as and R is the type that will be
/// commonly used and manipulated throughout the program
///
/// [AbstractIO] is not functional on its own and should have
/// the [ValueStorage] or the [ValueFetcher] mixin to provide functionality
///
/// [ValueStorage] allows the translated object to be stored and has additional mixins
/// to provide more functionality, such as treating this as a list with [ListStorage],
/// as a map with [MapStorage], or just give direct access to the value with [ValueAccess]
///
/// [ValueFetcher] is just meant to be an object that provides the user
/// easy access to input and output while not storing any data
abstract class AbstractIO<W, R> {
  /// translates the stored data from the type it was stored in (W) to the type
  /// that will be used (R)
  ///
  /// see [Translator] for more information
  final Translator<W, R> translator;

  /// provides an interface to send, recieve, request, and delete data of the
  /// writeable type W
  ///
  /// see [IOInterface] for more information
  ///
  /// this value is public in case it needs to be closed at the end of use
  final IOInterface<W> ioInterface;

  AbstractIO(
    this.ioInterface, {
    Translator<W, R> translator,
  }) : this.translator = translator ?? _CastingTranslator<W, R>() {
    initialize();
  }

  /// sends the data to wherever it is being stored and returns whether or not
  /// it was successful
  ///
  /// the core functionality of this function is implemented in ioInterface
  @protected
  Future<bool> sendData(R data) {
    return ioInterface.sendData(translator.translateReadable(data));
  }

  /// called when data is recieved by the [ioInterface]
  ///
  /// this method is overriden by [ValueFetcher] and [ValueStorage] and can be overriden
  /// to provide additional functionality although it is often not necessary
  @protected
  void onDataRecieved(R data);

  /// called to initialize this
  ///
  /// all overrides must call super and should have the annotaion "mustCallSuper"
  /// to alert future overides
  @protected
  @mustCallSuper
  void initialize() {
    ioInterface.onDataRecieved = (W data) {
      onDataRecieved(translator.translateWritable(data));
    };
  }
}

/// [ExternalIO] is an extension of [AbstractIO] to provide the function
/// of [lockAndUpdate] so that data can be locked and then updated, this
/// class requires that the [ioInterface] is an [ExternalIOInterface]
///
/// [lockAndUpdate] is much needed functionality when working with data that is
/// stored off device and modified by multiple devices because without it is possible
/// a data race could occur
///
/// for more information about writing and reading data visit the parent class [AbstractIO]
abstract class ExternalIO<W, R> extends AbstractIO<W, R> {
  ExternalIO(
    ExternalIOInterface<W> ioInterface, {
    Translator<W, R> translator,
  }) : super(ioInterface, translator: translator);

  /// [lockAndUpdate] will lock the server side data and allow you to update it with
  /// the [update] function
  ///
  /// the functionality of this is handled by the [ioInterface] which must be an [ExternalIOInterface]
  Future<R> lockAndUpdate(R Function(R newData) update) {
    return (ioInterface as ExternalIOInterface)
        .lockAndUpdate<R>(update, translator: translator);
  }
}

/// [ExternalMapIO] is meant to be the [AbstractIO] for when the data on the server side
/// is stored in some form of a map
///
/// it provides additional functionality to access and modify specific entries
///
/// [ExternalMapIO] is best used with [MapStorage] and [ExternalMapOptimizations]
/// to take full advantage of seperate entry storage
abstract class ExternalMapIO<KW, VW, KR, VR>
    extends ExternalIO<Map<KW, VW>, Map<KR, VR>> {
  /// the translator for the key from the key writable (KW) and the key readable (KR)
  Translator<KW, KR> keyTranslator;

  /// the translator for the value from the value writable (VW) and the value readable (VR)
  Translator<VW, VR> valueTranslator;

  ExternalMapIO(ExternalMapIOInterface<KW, VW> ioInterface,
      {this.keyTranslator, this.valueTranslator})
      : super(
          ioInterface,
          translator: TranslatorMap(
              keyTranslator ?? _CastingTranslator<KW, KR>(),
              valueTranslator ?? _CastingTranslator<VW, VR>()),
        ) {
    keyTranslator ??= _CastingTranslator<KW, KR>();
    valueTranslator ??= _CastingTranslator<VW, VR>();
  }

  /// creates a new entry with the given [value] the associated key is returned
  ///
  /// if you want to create a new entry with a specific key [setEntry] should be used instead
  ///
  /// the core functionality is handled by the [ioInterface]
  Future<KR> addEntry(VR value) async {
    return keyTranslator.translateWritable(
        await (ioInterface as ExternalMapIOInterface)
            .addEntry(valueTranslator.translateReadable(value)));
  }

  /// locks the entry with the given [key] and updates it using the [update] function
  ///
  /// returns the updated value in a future
  Future<VR> lockAndUpdateEntry(KR key, VR Function(VR newData) update) {
    return (ioInterface as ExternalMapIOInterface).lockAndUpdateEntry<VR>(
        keyTranslator.translateReadable(key), update,
        valueTranslator: valueTranslator);
  }

  /// returns the value of the entry with the given [key] in a future
  Future<VR> getEntry(KR key) async {
    return valueTranslator.translateWritable(
        await (ioInterface as ExternalMapIOInterface)
            .getEntry(keyTranslator.translateReadable(key)));
  }

  /// delets the entry with the given [key]
  ///
  /// returns whether or not the deletion was successful,
  /// a value of false does not necessarily mean the data was not deleted
  Future<bool> deleteEntry(KR key) {
    return (ioInterface as ExternalMapIOInterface)
        .deleteEntry(keyTranslator.translateReadable(key));
  }

  /// sets the entry with the given [key] to the given [value] and
  /// returns whether or not the setting was successful
  ///
  /// if the entry with [key] does not previously exist then it is created
  Future<bool> setEntry(KR key, VR value) {
    return (ioInterface as ExternalMapIOInterface).setEntry(
        keyTranslator.translateReadable(key),
        valueTranslator.translateReadable(value));
  }
}

/// takes two data types a readable R and a writable (W) and translates between
///
/// this proccess should be reversible such that if readable data is translated
/// to writable data using [translateReadable] then [translateWritable] should
/// give back the same readable data
abstract class Translator<W, R> {
  static bool test<R>(Translator<dynamic, R> t, R testData) {
    if (t.translateWritable(t.translateReadable(testData)) != testData) {
      return false;
    }
    return true;
  }

  const Translator();

  /// translates a readable data type into one that can be written
  /// such as a String
  W translateReadable(R readable);

  /// translates a writable data type into one that is readable
  ///
  /// if the writable is null a null value or a default value should be returned
  R translateWritable(W writable);

  /// translates between the writable type and the readable type throws an error
  /// if an unsupported type is given
  dynamic translate(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is R) {
      return translateReadable(data);
    } else if (data is W) {
      return translateWritable(data);
    } else {
      throw ErrorSummary(
          "${this.runtimeType} does not translate the type ${data.runtimeType}, supported types are $W and $R");
    }
  }
}

/// default used if no translator is provided all it does is cast the value to
/// the other data type (this is generally not recomended)
class _CastingTranslator<W, R> extends Translator<W, R> {
  const _CastingTranslator();

  @override
  W translateReadable(R readable) {
    return readable as W;
  }

  @override
  R translateWritable(W writable) {
    return writable as R;
  }
}

/// allows you to send data request data and recieve data all of type W
///
/// it is best practice that W should be the type that the data is sent as
/// such as a String or a list of bytes for files
///
/// this does need to be specific to files, it could be used to interface with servers
/// or anything else nessasary
abstract class IOInterface<W> {
  /// sends the data to wherever it is being stored and returns whether or not
  /// it was successful
  Future<bool> sendData(W data);

  /// this funtion is called whenever this receives some data
  ///
  /// DO NOT set it to a value or overide it that is handled by an [AbstractIO] object
  void Function(W data) onDataRecieved;

  /// requests the storage to send some data to this
  ///
  /// [requestData] must call [onDataRecieved] either directly or indirectly and
  /// if at all possible before the Future returns
  ///
  /// instead of throwing an error if something doesn't work consider passing null to [onDataRecieved]
  ///
  /// if not some functionality mixins may not work properly, most at risk is [ValueFetcher]
  Future<void> requestData();

  /// deletes data
  ///
  /// returns whether or not the deletion was successful,
  /// a value of false does not necessarily mean the data was not deleted
  Future<bool> deleteData();
}

/// allows you to send data request data and recieve data all of type W
///
/// it is best practice that W should be the type that the data is sent as
/// such as a String or a list of bytes for files
///
/// [ExternalIOInterface] adds the functionality to [lockAndUpdate] data,
/// this is often nessecary functionality when storing data off device to avoid race conditions
abstract class ExternalIOInterface<W> extends IOInterface<W> {
  ExternalIOInterface();

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

/// allows you to send data request data and recieve data all of type W
///
/// it is best practice that W should be the type that the data is sent as
/// such as a String or a list of bytes for files
///
/// [ExternalIOInterface] adds the functionality to [lockAndUpdate] data,
/// this is often nessecary functionality when storing data off device to avoid race conditions
///
/// [ExternalMapIOInterface] adds additional functionality for when the data is stored in the form of a map
abstract class ExternalMapIOInterface<KW, VW>
    extends ExternalIOInterface<Map<KW, VW>> {
  /// lock and update a specific entry with the given [key]
  ///
  /// should follow the same general protocol as [lockAndUpdate]
  Future<V> lockAndUpdateEntry<V>(KW key, V Function(V newData) update,
      {Translator<VW, V> valueTranslator});

  /// get theentry for the [key] returns the value in a future
  Future<VW> getEntry(KW key);

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
}
