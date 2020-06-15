import 'dart:convert';
import 'dart:typed_data';
import 'package:abstract_io/abstract_io/abstract_base.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

//TODO Documentation

mixin TranslatorDefaultValue<W,R> on Translator<W,R>{
  R get defaultValue;

  @override
  @mustCallSuper
  translateWritable(writable) {
    R val;
    try {
      val = super.translateWritable(writable);
    } catch (e) {
      val = null;
    }

    if(val == null){
      val = defaultValue;
    }

    return val;
  }
  
}


class TranslatorLink<W,B,R> extends Translator<W,R>{

  final Translator<W,B> writingEnd;
  final Translator<B,R> readingEnd;

  const TranslatorLink(this.readingEnd, this.writingEnd);

  @override
  W translateReadable(R readable) {
    return writingEnd.translateReadable(readingEnd.translateReadable(readable));
  }
  
  @override
  R translateWritable(W writable) {
    return readingEnd.translateWritable(writingEnd.translateWritable(writable));
  }
  
}


class TranslatorMap<KW,VW, KR,VR> extends Translator<Map<KW,VW>, Map<KR,VR>>{

  final Translator<KW,KR> keyTranslator;
  final Translator<VW,VR> valueTranslator;

  const TranslatorMap(
    this.keyTranslator,
    this.valueTranslator
  );



  @override
  Map<KW, VW> translateReadable(Map<KR,VR> readable) {
    return readable.map<KW,VW>((KR key, VR value){
      return MapEntry(
        keyTranslator.translateReadable(key), 
        valueTranslator.translateReadable(value)
      );
    });
  }

  @override
  Map<KR, VR> translateWritable(Map<KW,VW> writable) {
    return writable.map<KR,VR>((KW key, VW value){
      return MapEntry(
        keyTranslator.translateWritable(key), 
        valueTranslator.translateWritable(value)
      );
    });
  }

}


class SameTypeTranslator<T> extends Translator<T,T>{
  @override
  T translateReadable(T readable) {
    return readable;
  }

  @override
  T translateWritable(T writable) {
    return writable;
  }
  
}


class JSONStringTranslator extends Translator<String, dynamic>{

  const JSONStringTranslator();

  
  @override
  String translateReadable(readable) {
    return json.encode(readable);
  }
  
  @override
  translateWritable(String writable) {
    return json.decode(writable);
  }
  
}


class ImageByteTranslator extends Translator<Uint8List, MemoryImage>{

  double _scale;

  ImageByteTranslator({
    double scale = 1
  }): _scale = scale ?? 1,
    super();

  set scale(double s){
    if(s == null){
      return;
    }
    _scale = s;
  }

  double get scale => _scale;

  @override
  Uint8List translateReadable(MemoryImage readable) {
    return readable.bytes;
  }
  
  @override
  MemoryImage translateWritable(Uint8List writeable) {
    return MemoryImage(writeable, scale: _scale);
  }
  
}


