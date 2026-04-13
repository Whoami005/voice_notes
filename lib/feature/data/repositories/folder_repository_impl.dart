import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/feature/data/local/data_sources/folder_local_data_source.dart';
import 'package:voice_notes/feature/data/local/mappers/folder_mapper.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';

/// Реализация репозитория для управления папками
@Singleton(as: FolderRepository)
class FolderRepositoryImpl implements FolderRepository {
  final FolderLocalDataSource _dataSource;

  FolderRepositoryImpl(this._dataSource);

  @override
  Future<List<FolderEntity>> getAll() async {
    final objects = await _dataSource.getAll();

    return [for (final obj in objects) FolderMapper.toDomain(obj)];
  }

  @override
  Future<FolderEntity> getByUid(String uid) async {
    final obj = await _dataSource.getByUid(uid);

    return FolderMapper.toDomain(obj);
  }

  @override
  Future<FolderEntity> create({
    required String name,
    required Color color,
    required IconRefEntity icon,
    String? description,
  }) async {
    final now = DateTime.now();

    final folderObject = FolderObject(
      uid: UuidManager.v1(),
      name: name,
      description: description,
      colorValue: color.toARGB32(),
      iconRef: icon.serialize(),
      createdAt: now,
      updatedAt: now,
    );

    final newObj = await _dataSource.save(folderObject);

    return FolderMapper.toDomain(newObj);
  }

  @override
  Future<FolderEntity> update(FolderEntity folder) async {
    final existing = await _dataSource.getByUid(folder.uid);

    final updatedFolder = folder.copyWith(updatedAt: DateTime.now());
    FolderMapper.updateEntity(existing, updatedFolder);

    final newObj = await _dataSource.update(existing);

    return FolderMapper.toDomain(newObj);
  }

  @override
  Future<void> delete(String uid) => _dataSource.delete(uid);

  @override
  Future<void> deleteWithNotes(String uid) async {
    // DataSource транзакционно удаляет folder + все NoteObject + связанные
    // NoteAudioObject и возвращает список путей к аудиофайлам, которые нужно
    // подчистить с диска. БД уже консистентна — file delete best-effort.
    final audioRelativePaths = await _dataSource.deleteWithNotes(uid);

    await Future.wait([
      for (final relativePath in audioRelativePaths)
        AudioPaths.deleteFile(relativePath),
    ]);
  }

  @override
  Stream<List<FolderEntity>> watchAll() =>
      _dataSource.watchAll().map(FolderMapper.toDomainList);

  @override
  Stream<FolderEntity?> watchByUid(String uid) {
    return _dataSource
        .watchByUid(uid)
        .map((obj) => obj != null ? FolderMapper.toDomain(obj) : null);
  }
}
