import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class TagEntity extends Equatable {
  final String uid;
  final String name;
  final Color? color;
  final DateTime createdAt;

  const TagEntity({
    required this.uid,
    required this.name,
    required this.createdAt,
    this.color,
  });

  @override
  List<Object?> get props => [uid, name, color, createdAt];

  TagEntity copyWith({
    String? uid,
    String? name,
    Color? color,
    DateTime? createdAt,
  }) {
    return TagEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
