/// Abstract IO is designed to simplify and generalize saving data both localy and externaly
/// 
/// start using it by extending the [AbstractIO] class and mixing in either
/// [ValueStorage] or [ValueFetcher]
library abstract_io;

export 'abstract_io/abstract_base.dart';
export 'abstract_io/additional_functionality.dart';
export 'abstract_io/value_fetcher.dart';
export 'abstract_io/value_storage.dart';

export 'translators/translators.dart';
export 'translators/encodable_translators.dart';
