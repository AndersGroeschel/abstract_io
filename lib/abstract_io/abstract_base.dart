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
  }) : this.translator = translator?? CastingTranslator<W, R>() {
    initialize();
  }

  /// sends the data to wherever it is being stored and returns whether or not
  /// it was successful
  ///
  /// the core functionality of this function is implemented in ioInterface
  @protected
  Future<bool> setData(R data) {
    return ioInterface.setData(translator.translateReadable(data));
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


/// allows you to send data request data and recieve data all of type W
///
/// it is best practice that W should be the type that the data is sent as
/// such as a String or a list of bytes for files
///
/// this does need to be specific to files, it could be used to interface with servers
/// or anything else nessasary
abstract class IOInterface<W> {
  /// sets the data in the storage place to the given data and returns whether or not
  /// it was successful
  Future<bool> setData(W data);

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


