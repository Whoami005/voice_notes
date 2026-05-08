part of 'import_data_sheet_cubit.dart';

class ImportDataSheetState extends Equatable {
  final XFile? selectedFile;
  final AppDataImportPreview? preview;
  final int activeQueueCount;
  final bool isPicking;
  final bool isInspecting;
  final bool isImporting;

  const ImportDataSheetState({
    this.selectedFile,
    this.preview,
    this.activeQueueCount = 0,
    this.isPicking = false,
    this.isInspecting = false,
    this.isImporting = false,
  });

  bool get isQueueBusy => activeQueueCount > 0;

  bool get canSubmit =>
      selectedFile != null &&
      preview != null &&
      !isQueueBusy &&
      !isPicking &&
      !isInspecting &&
      !isImporting;

  bool get isBusy => isPicking || isInspecting || isImporting;

  ImportDataSheetState copyWith({
    XFile? Function()? selectedFile,
    AppDataImportPreview? Function()? preview,
    int? activeQueueCount,
    bool? isPicking,
    bool? isInspecting,
    bool? isImporting,
  }) {
    return ImportDataSheetState(
      selectedFile: selectedFile != null ? selectedFile() : this.selectedFile,
      preview: preview != null ? preview() : this.preview,
      activeQueueCount: activeQueueCount ?? this.activeQueueCount,
      isPicking: isPicking ?? this.isPicking,
      isInspecting: isInspecting ?? this.isInspecting,
      isImporting: isImporting ?? this.isImporting,
    );
  }

  @override
  List<Object?> get props => [
    selectedFile,
    preview,
    activeQueueCount,
    isPicking,
    isInspecting,
    isImporting,
  ];
}
