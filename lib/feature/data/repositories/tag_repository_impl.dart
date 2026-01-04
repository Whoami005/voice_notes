import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/feature/data/local/data_sources/tag_local_data_source.dart';
import 'package:voice_notes/feature/data/local/mappers/tag_mapper.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/tag_repository.dart';

/// Реализация репозитория для управления тегами
@Singleton(as: TagRepository)
class TagRepositoryImpl implements TagRepository {
  final TagLocalDataSource _dataSource;

  TagRepositoryImpl(this._dataSource);

  @override
  Future<List<TagEntity>> getAll() async {
    final objects = await _dataSource.getAll();
    return TagMapper.toDomainList(objects);
  }

  @override
  Future<TagEntity?> getByName(String name) async {
    final obj = await _dataSource.getByName(name);
    if (obj == null) return null;

    return TagMapper.toDomain(obj);
  }

  @override
  Future<TagEntity> create({required String name, Color? color}) async {
    final tag = TagObject(
      name: name.toLowerCase().trim(),
      colorValue: color?.toARGB32(),
      createdAt: DateTime.now(),
    );

    final newObj = await _dataSource.save(tag);

    return TagMapper.toDomain(newObj);
  }

  @override
  Future<TagEntity> getOrCreate({required String name, Color? color}) async {
    final obj = await _dataSource.getOrCreate(
      name,
      colorValue: color?.toARGB32(),
    );

    return TagMapper.toDomain(obj);
  }

  @override
  Future<void> delete(String name) async {
    await _dataSource.deleteByName(name);
  }

  @override
  Stream<List<TagEntity>> watchAll() =>
      _dataSource.watchAll().map(TagMapper.toDomainList);
}
