class AsrModelEntity {
  final String id;
  final String name;
  final String engine;
  final String size;
  final String languages;
  final String description;
  final bool isDownloaded;
  final bool isSelected;
  final double? downloadProgress;

  const AsrModelEntity({
    required this.id,
    required this.name,
    required this.engine,
    required this.size,
    required this.languages,
    required this.description,
    this.isDownloaded = false,
    this.isSelected = false,
    this.downloadProgress,
  });
}
