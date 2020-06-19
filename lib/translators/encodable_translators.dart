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
  /// the new object returned by [decode] should not be related to this
  Encodable decode(Map<String, dynamic> json);

  /// default implementation returns a new deep copy of this
  /// 
  /// override this method to make a more efficient clone 
  /// or handle cases where there may be errors
  Encodable clone() => this.decode(this.encode());

}

/// translates an [Encodable] object into a String
class EncodableStringTranslator<T extends Encodable> extends Translator<String, T>{

  /// the value that will be used for decodeing the JSON
  final T decoder;

  const EncodableStringTranslator(
    this.decoder
  );

  @override
  String translateReadable(T readable) {
    return json.encode(readable.encode());
  }
  
  @override
  T translateWritable(String writable) {
    return decoder.decode(json.decode(writable));
  }

}

/// translates a list of [Encodable] objects to a list of JSON maps
class EncodableMapListTranslator<T extends Encodable> extends Translator<List<Map<String, dynamic>>, List<T>>{

  final T decoder;

  const EncodableMapListTranslator(
    this.decoder
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
      vals.add(decoder.decode(val));
    }
    return vals;
  }

}


/// translates an [Encodable] object into a JSON Map
class EncodableMapTranslator<T extends Encodable> extends Translator<Map<String, dynamic>, T>{
  final T decoder;

  const EncodableMapTranslator(
    this.decoder
  );

  @override
  Map<String, dynamic> translateReadable(T readable) {
    return readable.encode();
  }
  
  @override
  T translateWritable(Map<String, dynamic> writable) {
    return decoder.decode(writable);
  }
}

