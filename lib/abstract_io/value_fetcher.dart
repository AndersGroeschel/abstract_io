import 'abstract_base.dart';


/// a mixin on [AbstractIO] to allow this to easily read and write values without any
/// purposeful storage of a value
mixin ValueFetcher<W,R> on AbstractIO<W,R>{

  /// temporary value so that data from [onDataRecieved] can be transferred easily
  R _tempVal;

  /// write [data] using the [ioInterface] given to this
  Future<bool> write(R data) async {
    return await ioInterface.sendData(translator.translateReadable(data));
  }

  /// read the value that was saved using the [ioInterface] given to this
  Future<R> read() async {
    await ioInterface.requestData();
    R val = _tempVal;
    _tempVal = null;
    return val;
  }

  /// sets [_tempVal] to [data] so that the value can be retrieved and returned in [read]
  @override
  void onDataRecieved(R data) {
    _tempVal = data;
  }

}



