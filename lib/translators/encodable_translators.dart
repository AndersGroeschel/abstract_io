import 'dart:convert';

import 'package:abstract_io/abstract_io.dart';

/// mixin that makes a class encodable
/// 
/// as a bonus it also creates a clone function
mixin Encodable{
  
  /// returns this as a JSON map 
  Map<String, dynamic> encode();

  /// creates a new object based on the given [json]
  /// 
  /// it is best practice that the new object returned by
  /// [decode] is not related to this
  Encodable decode(Map<String, dynamic> json);

  /// default implementation returns a new deep copy of this
  /// 
  /// override this method to make a more efficient clone 
  /// or handle cases where there may be errors
  Encodable clone() => this.decode(this.encode());

}

class EncodableStringTranslator<T extends Encodable> extends Translator<String, T>{

  final T encoder;

  const EncodableStringTranslator(
    this.encoder
  );

  @override
  String translateReadable(T readable) {
    return json.encode(readable.encode());
  }
  
  @override
  T translateWritable(String writable) {
    return encoder.decode(json.decode(writable));
  }

}

class EncodableMapListTranslator<T extends Encodable> extends Translator<List<Map<String, dynamic>>, List<T>>{

  final T encoder;

  const EncodableMapListTranslator(
    this.encoder
  );

  @override
  List<Map<String, dynamic>> translateReadable(List<T> readable) {
    List<Map<String, dynamic>> jsonList = List(readable.length);

    int index = 0;
    for(T val in readable){
      jsonList[index] = val.encode();
      index++;
    }

    return jsonList;
  }
  
  @override
  List<T> translateWritable(List<Map<String, dynamic>> writable) {
    List<T> vals = [];
    for(Map<String, dynamic> val in writable){
      vals.add(encoder.decode(val));
    }
    return vals;
  }

}

class EncodableMapTranslator<T extends Encodable> extends Translator<Map<String, dynamic>, T>{
  final T encoder;

  const EncodableMapTranslator(
    this.encoder
  );

  @override
  Map<String, dynamic> translateReadable(T readable) {
    return readable.encode();
  }
  
  @override
  T translateWritable(Map<String, dynamic> writable) {
    return encoder.decode(writable);
  }
}

