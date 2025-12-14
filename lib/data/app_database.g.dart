// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashedFileNameMeta = const VerificationMeta(
    'hashedFileName',
  );
  @override
  late final GeneratedColumn<String> hashedFileName = GeneratedColumn<String>(
    'hashed_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaFolderPathMeta = const VerificationMeta(
    'mediaFolderPath',
  );
  @override
  late final GeneratedColumn<String> mediaFolderPath = GeneratedColumn<String>(
    'media_folder_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileHash,
    hashedFileName,
    mediaFolderPath,
    originalFileName,
    fileType,
    tags,
    thumbnailPath,
    duration,
    width,
    height,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('hashed_file_name')) {
      context.handle(
        _hashedFileNameMeta,
        hashedFileName.isAcceptableOrUnknown(
          data['hashed_file_name']!,
          _hashedFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hashedFileNameMeta);
    }
    if (data.containsKey('media_folder_path')) {
      context.handle(
        _mediaFolderPathMeta,
        mediaFolderPath.isAcceptableOrUnknown(
          data['media_folder_path']!,
          _mediaFolderPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaFolderPathMeta);
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fileHash, mediaFolderPath},
  ];
  @override
  MediaItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      hashedFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hashed_file_name'],
      )!,
      mediaFolderPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_folder_path'],
      )!,
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItem extends DataClass implements Insertable<MediaItem> {
  final int id;
  final String fileHash;
  final String hashedFileName;
  final String mediaFolderPath;
  final String originalFileName;
  final String fileType;
  final String? tags;
  final String? thumbnailPath;
  final int? duration;
  final int width;
  final int height;
  const MediaItem({
    required this.id,
    required this.fileHash,
    required this.hashedFileName,
    required this.mediaFolderPath,
    required this.originalFileName,
    required this.fileType,
    this.tags,
    this.thumbnailPath,
    this.duration,
    required this.width,
    required this.height,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_hash'] = Variable<String>(fileHash);
    map['hashed_file_name'] = Variable<String>(hashedFileName);
    map['media_folder_path'] = Variable<String>(mediaFolderPath);
    map['original_file_name'] = Variable<String>(originalFileName);
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      fileHash: Value(fileHash),
      hashedFileName: Value(hashedFileName),
      mediaFolderPath: Value(mediaFolderPath),
      originalFileName: Value(originalFileName),
      fileType: Value(fileType),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      width: Value(width),
      height: Value(height),
    );
  }

  factory MediaItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItem(
      id: serializer.fromJson<int>(json['id']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      hashedFileName: serializer.fromJson<String>(json['hashedFileName']),
      mediaFolderPath: serializer.fromJson<String>(json['mediaFolderPath']),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      fileType: serializer.fromJson<String>(json['fileType']),
      tags: serializer.fromJson<String?>(json['tags']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      duration: serializer.fromJson<int?>(json['duration']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileHash': serializer.toJson<String>(fileHash),
      'hashedFileName': serializer.toJson<String>(hashedFileName),
      'mediaFolderPath': serializer.toJson<String>(mediaFolderPath),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'fileType': serializer.toJson<String>(fileType),
      'tags': serializer.toJson<String?>(tags),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'duration': serializer.toJson<int?>(duration),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
    };
  }

  MediaItem copyWith({
    int? id,
    String? fileHash,
    String? hashedFileName,
    String? mediaFolderPath,
    String? originalFileName,
    String? fileType,
    Value<String?> tags = const Value.absent(),
    Value<String?> thumbnailPath = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    int? width,
    int? height,
  }) => MediaItem(
    id: id ?? this.id,
    fileHash: fileHash ?? this.fileHash,
    hashedFileName: hashedFileName ?? this.hashedFileName,
    mediaFolderPath: mediaFolderPath ?? this.mediaFolderPath,
    originalFileName: originalFileName ?? this.originalFileName,
    fileType: fileType ?? this.fileType,
    tags: tags.present ? tags.value : this.tags,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    duration: duration.present ? duration.value : this.duration,
    width: width ?? this.width,
    height: height ?? this.height,
  );
  MediaItem copyWithCompanion(MediaItemsCompanion data) {
    return MediaItem(
      id: data.id.present ? data.id.value : this.id,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      hashedFileName: data.hashedFileName.present
          ? data.hashedFileName.value
          : this.hashedFileName,
      mediaFolderPath: data.mediaFolderPath.present
          ? data.mediaFolderPath.value
          : this.mediaFolderPath,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      tags: data.tags.present ? data.tags.value : this.tags,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      duration: data.duration.present ? data.duration.value : this.duration,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItem(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('hashedFileName: $hashedFileName, ')
          ..write('mediaFolderPath: $mediaFolderPath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileType: $fileType, ')
          ..write('tags: $tags, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileHash,
    hashedFileName,
    mediaFolderPath,
    originalFileName,
    fileType,
    tags,
    thumbnailPath,
    duration,
    width,
    height,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == this.id &&
          other.fileHash == this.fileHash &&
          other.hashedFileName == this.hashedFileName &&
          other.mediaFolderPath == this.mediaFolderPath &&
          other.originalFileName == this.originalFileName &&
          other.fileType == this.fileType &&
          other.tags == this.tags &&
          other.thumbnailPath == this.thumbnailPath &&
          other.duration == this.duration &&
          other.width == this.width &&
          other.height == this.height);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<int> id;
  final Value<String> fileHash;
  final Value<String> hashedFileName;
  final Value<String> mediaFolderPath;
  final Value<String> originalFileName;
  final Value<String> fileType;
  final Value<String?> tags;
  final Value<String?> thumbnailPath;
  final Value<int?> duration;
  final Value<int> width;
  final Value<int> height;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.hashedFileName = const Value.absent(),
    this.mediaFolderPath = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.tags = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String fileHash,
    required String hashedFileName,
    required String mediaFolderPath,
    required String originalFileName,
    required String fileType,
    this.tags = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
  }) : fileHash = Value(fileHash),
       hashedFileName = Value(hashedFileName),
       mediaFolderPath = Value(mediaFolderPath),
       originalFileName = Value(originalFileName),
       fileType = Value(fileType);
  static Insertable<MediaItem> custom({
    Expression<int>? id,
    Expression<String>? fileHash,
    Expression<String>? hashedFileName,
    Expression<String>? mediaFolderPath,
    Expression<String>? originalFileName,
    Expression<String>? fileType,
    Expression<String>? tags,
    Expression<String>? thumbnailPath,
    Expression<int>? duration,
    Expression<int>? width,
    Expression<int>? height,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileHash != null) 'file_hash': fileHash,
      if (hashedFileName != null) 'hashed_file_name': hashedFileName,
      if (mediaFolderPath != null) 'media_folder_path': mediaFolderPath,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (fileType != null) 'file_type': fileType,
      if (tags != null) 'tags': tags,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileHash,
    Value<String>? hashedFileName,
    Value<String>? mediaFolderPath,
    Value<String>? originalFileName,
    Value<String>? fileType,
    Value<String?>? tags,
    Value<String?>? thumbnailPath,
    Value<int?>? duration,
    Value<int>? width,
    Value<int>? height,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      fileHash: fileHash ?? this.fileHash,
      hashedFileName: hashedFileName ?? this.hashedFileName,
      mediaFolderPath: mediaFolderPath ?? this.mediaFolderPath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      tags: tags ?? this.tags,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (hashedFileName.present) {
      map['hashed_file_name'] = Variable<String>(hashedFileName.value);
    }
    if (mediaFolderPath.present) {
      map['media_folder_path'] = Variable<String>(mediaFolderPath.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('hashedFileName: $hashedFileName, ')
          ..write('mediaFolderPath: $mediaFolderPath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('fileType: $fileType, ')
          ..write('tags: $tags, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [mediaItems];
}

typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      required String fileHash,
      required String hashedFileName,
      required String mediaFolderPath,
      required String originalFileName,
      required String fileType,
      Value<String?> tags,
      Value<String?> thumbnailPath,
      Value<int?> duration,
      Value<int> width,
      Value<int> height,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      Value<String> fileHash,
      Value<String> hashedFileName,
      Value<String> mediaFolderPath,
      Value<String> originalFileName,
      Value<String> fileType,
      Value<String?> tags,
      Value<String?> thumbnailPath,
      Value<int?> duration,
      Value<int> width,
      Value<int> height,
    });

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashedFileName => $composableBuilder(
    column: $table.hashedFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFolderPath => $composableBuilder(
    column: $table.mediaFolderPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashedFileName => $composableBuilder(
    column: $table.hashedFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFolderPath => $composableBuilder(
    column: $table.mediaFolderPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get hashedFileName => $composableBuilder(
    column: $table.hashedFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaFolderPath => $composableBuilder(
    column: $table.mediaFolderPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);
}

class $$MediaItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaItemsTable,
          MediaItem,
          $$MediaItemsTableFilterComposer,
          $$MediaItemsTableOrderingComposer,
          $$MediaItemsTableAnnotationComposer,
          $$MediaItemsTableCreateCompanionBuilder,
          $$MediaItemsTableUpdateCompanionBuilder,
          (
            MediaItem,
            BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>,
          ),
          MediaItem,
          PrefetchHooks Function()
        > {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String> hashedFileName = const Value.absent(),
                Value<String> mediaFolderPath = const Value.absent(),
                Value<String> originalFileName = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                fileHash: fileHash,
                hashedFileName: hashedFileName,
                mediaFolderPath: mediaFolderPath,
                originalFileName: originalFileName,
                fileType: fileType,
                tags: tags,
                thumbnailPath: thumbnailPath,
                duration: duration,
                width: width,
                height: height,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileHash,
                required String hashedFileName,
                required String mediaFolderPath,
                required String originalFileName,
                required String fileType,
                Value<String?> tags = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                fileHash: fileHash,
                hashedFileName: hashedFileName,
                mediaFolderPath: mediaFolderPath,
                originalFileName: originalFileName,
                fileType: fileType,
                tags: tags,
                thumbnailPath: thumbnailPath,
                duration: duration,
                width: width,
                height: height,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaItemsTable,
      MediaItem,
      $$MediaItemsTableFilterComposer,
      $$MediaItemsTableOrderingComposer,
      $$MediaItemsTableAnnotationComposer,
      $$MediaItemsTableCreateCompanionBuilder,
      $$MediaItemsTableUpdateCompanionBuilder,
      (MediaItem, BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem>),
      MediaItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
}
