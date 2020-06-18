import 'abstract_base.dart';


/// a mixin on [AbstractIO] to allow this to easily read and write values without any
/// purposeful storage of a value
mixin ValueFetcher<W,R> on AbstractIO<W,R>{

  /// temporary value so that data from [onDataRecieved] can be transferred easily
  R _tempVal;

  /// write [data] using the [ioInterface] given to this
  Future<bool> write(R data){
    return sendData(data);
  }

  /// read the value that was saved using the [ioInterface] given to this
  Future<R> read() async {
    await ioInterface.requestData();
    R val = _tempVal;
    _tempVal = null;
    if(val is FetcherAccess){
      val._io = this;
    }
    return val;
  }

  /// sets [_tempVal] to [data] so that the value can be retrieved and returned in [read]
  @override
  void onDataRecieved(R data) {
    _tempVal = data;
  }

}

/// a mixin that allows this to write itself using the [ValueFetcher] that retrieved it
mixin FetcherAccess{

  /// a reference to the [ValueFetcher] that retrieved this
  ValueFetcher _io;

  /// writes this using the [ValueFetcher] that retrieved it
  Future<bool> write() => _io.write(this);
}



