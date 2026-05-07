// DB-persisted enum. Int values are part of the DB schema.
// Never reorder existing entries; only append new variants at the end.
enum NoteOriginType {
  manual(0),
  audio(1);

  const NoteOriginType(this.value);

  final int value;

  static NoteOriginType fromValue(int value) {
    return values.firstWhere((type) => type.value == value);
  }
}
