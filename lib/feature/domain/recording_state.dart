enum RecordingState { idle, recording, transcribing }

enum SearchFilter {
  all(title: 'Все'),
  text(title: 'Текст'),
  tags(title: 'Теги'),
  date(title: 'Дата');

  const SearchFilter({required this.title});

  final String title;
}
