import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/path/app_path_provider.dart';

/// Абстракция для тестирования и гибкости
abstract interface class DatabaseClient {
  Box<T> box<T>();

  /// Выполнить операции в транзакции (атомарно)
  R runInTransaction<R>(R Function() action, {TxMode mode = TxMode.write});

  Future<R> runInTransactionAsync<R, P>(
    R Function(Store, P) action, {
    required P param,
    TxMode mode = TxMode.write,
  });

  Future<void> close();
}

/// Реализация ObjectBox
@Singleton(as: DatabaseClient)
class ObjectBoxDatabase implements DatabaseClient {
  late final Store _store;

  ObjectBoxDatabase._(this._store);

  @FactoryMethod(preResolve: true)
  static Future<ObjectBoxDatabase> create() async {
    final doc = await AppPathProvider.getApplicationDocumentsDirectory();
    final dbDirectory = p.join(doc.path, 'voice-notes-box_db');

    final store = await openStore(directory: dbDirectory);

    return ObjectBoxDatabase._(store);
  }

  @override
  Box<T> box<T>() => _store.box<T>();

  @override
  R runInTransaction<R>(R Function() action, {TxMode mode = TxMode.write}) =>
      _store.runInTransaction(mode, action);

  @override
  Future<R> runInTransactionAsync<R, P>(
    R Function(Store, P) action, {
    required P param,
    TxMode mode = TxMode.write,
  }) => _store.runInTransactionAsync(mode, action, param);

  @override
  @disposeMethod
  Future<void> close() async => _store.close();
}
