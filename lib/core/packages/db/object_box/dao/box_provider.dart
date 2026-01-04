import 'package:objectbox/objectbox.dart';

/// Провайдер для получения Box нужного типа.
/// Работает как с Store (в транзакциях), так и с DatabaseClient.
typedef BoxProvider = Box<T> Function<T>();
