import 'package:flutter/material.dart';

class TagEntity {
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

  TagEntity copyWith({String? uid, String? name, Color? color, DateTime? createdAt}) {
    return TagEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
