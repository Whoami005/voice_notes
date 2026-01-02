import 'package:objectbox/objectbox.dart';

/// ObjectBox entity для хранения информации о скачанных моделях
@Entity()
class DownloadedModelObject {
  @Id()
  int id = 0;

  /// Идентификатор модели (например 'whisper-small', 'parakeet-tdt-v3')
  @Unique()
  String modelId;

  /// Имя директории модели (например 'sherpa-onnx-whisper-small')
  String modelDirName;

  /// Относительный путь к директории модели (от Documents)
  String localPath;

  /// Является ли модель выбранной (активной)
  bool isSelected;

  /// Дата и время скачивания
  @Property(type: PropertyType.dateNanoUtc)
  @Index()
  DateTime downloadedAt;

  /// Размер модели в байтах после распаковки
  int fileSizeBytes;

  DownloadedModelObject({
    required this.modelId,
    required this.modelDirName,
    required this.localPath,
    required this.downloadedAt,
    this.isSelected = false,
    this.fileSizeBytes = 0,
  });
}
