enum SortField {
  dateAdded,
  mediaDate,
  fileType,
}

enum SortDirection {
  asc,
  desc,
}

extension SortFieldLabel on SortField {
  String get label => switch (this) {
    SortField.dateAdded => 'Date Added',
    SortField.mediaDate => 'Media Date',
    SortField.fileType  => 'File Type',
  };

  bool get hasDirection => this != SortField.fileType;
}
