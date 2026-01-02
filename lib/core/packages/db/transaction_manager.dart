import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';

/// Менеджер транзакций для атомарных операций с БД
@singleton
class TransactionManager {
  final DatabaseClient _db;

  TransactionManager(this._db);

  /// Выполнить операции синхронно в транзакции
  R runInTransaction<R>(R Function() action, {TxMode mode = TxMode.write}) =>
      _db.runInTransaction(action, mode: mode);

  /// Выполнить операции асинхронно в отдельном изоляте
  Future<R> runInTransactionAsync<R, P>(
    R Function(Store, P) action, {
    required P param,
    TxMode mode = TxMode.write,
  }) => _db.runInTransactionAsync(action, param: param, mode: mode);
}
