import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'package:abstract_io/abstract_io/abstract_base.dart';
import 'package:flutter/rendering.dart' show MemoryImage;


/// links two translators together using an in between type [B]
///
/// essentially takes two translators and feeds them into each other to get
/// the full translation
class TranslatorLink<W, B, R> extends Translator<W, R> {
  /// translates between the writable type [W] and the inbetween type [B]
  final Translator<W, B> writingEnd;

  /// translates between the readable type [R] to the inbetween type [B]
  final Translator<B, R> readingEnd;

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

/// creates a translator to translate between readable types and writable types
class TranslatorMap<KW, VW, KR, VR>
    extends Translator<Map<KW, VW>, Map<KR, VR>> {
  /// the translator used to translate the key between it's readable type and writable type
  final Translator<KW, KR> keyTranslator;

  /// the translator used to translate the value between it's readable type and writable type
  final Translator<VW, VR> valueTranslator;

  const TranslatorMap(this.keyTranslator, this.valueTranslator);

  @override
  Map<KW, VW> translateReadable(Map<KR, VR> readable) {
    return readable.map<KW, VW>((KR key, VR value) {
      return MapEntry(keyTranslator.translateReadable(key),
          valueTranslator.translateReadable(value));
    });
  }

  @override
  Map<KR, VR> translateWritable(Map<KW, VW> writable) {
    return writable.map<KR, VR>((KW key, VW value) {
      return MapEntry(keyTranslator.translateWritable(key),
          valueTranslator.translateWritable(value));
    });
  }
}

/// does nothing to the value and returns it back
class SameTypeTranslator<T> extends Translator<T, T> {
  const SameTypeTranslator();

  @override
  T translateReadable(T readable) {
    return readable;
  }

  @override
  T translateWritable(T writable) {
    return writable;
  }

  @override
  dynamic translate(dynamic data) {
    return data;
  }
}

/// translates between a JSON map and a String
class JSONStringTranslator extends Translator<String, dynamic> {
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

/// translates a list of bytes to a [MemoryImage]
class ImageByteTranslator extends Translator<Uint8List, MemoryImage> {
  /// the scale of the image
  double _scale;

  ImageByteTranslator({double scale = 1})
      : _scale = scale ?? 1,
        super();

  /// sets the scale of the image when it is loaded
  set scale(double s) {
    if (s == null) {
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
