import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';

class FolderEntity extends Equatable {
  final String uid;
  final String name;
  final String? description;
  final Color color;
  final IconRefEntity icon;
  final int notesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderEntity({
    required this.uid,
    required this.name,
    required this.color,
    required this.icon,
    required this.notesCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  /// Getter для UI совместимости с IconData.
  IconData get iconData => icon.toIconData() ?? Icons.folder;

  @override
  List<Object?> get props => [
    uid,
    name,
    description,
    color,
    icon,
    notesCount,
    createdAt,
    updatedAt,
  ];

  FolderEntity copyWith({
    String? uid,
    String? name,
    String? description,
    Color? color,
    IconRefEntity? icon,
    int? notesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      notesCount: notesCount ?? this.notesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
