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
  static const VerificationMeta _perceptualHashMeta = const VerificationMeta(
    'perceptualHash',
  );
  @override
  late final GeneratedColumn<String> perceptualHash = GeneratedColumn<String>(
    'perceptual_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioFingerprintMeta = const VerificationMeta(
    'audioFingerprint',
  );
  @override
  late final GeneratedColumn<String> audioFingerprint = GeneratedColumn<String>(
    'audio_fingerprint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileHash,
    hashedFileName,
    mediaFolderPath,
    originalFileName,
    fileType,
    thumbnailPath,
    duration,
    width,
    height,
    perceptualHash,
    audioFingerprint,
    date,
    time,
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
    if (data.containsKey('perceptual_hash')) {
      context.handle(
        _perceptualHashMeta,
        perceptualHash.isAcceptableOrUnknown(
          data['perceptual_hash']!,
          _perceptualHashMeta,
        ),
      );
    }
    if (data.containsKey('audio_fingerprint')) {
      context.handle(
        _audioFingerprintMeta,
        audioFingerprint.isAcceptableOrUnknown(
          data['audio_fingerprint']!,
          _audioFingerprintMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
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
      perceptualHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}perceptual_hash'],
      ),
      audioFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_fingerprint'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      ),
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
  final String? thumbnailPath;
  final int? duration;
  final int width;
  final int height;
  final String? perceptualHash;
  final String? audioFingerprint;
  final String? date;
  final String? time;
  const MediaItem({
    required this.id,
    required this.fileHash,
    required this.hashedFileName,
    required this.mediaFolderPath,
    required this.originalFileName,
    required this.fileType,
    this.thumbnailPath,
    this.duration,
    required this.width,
    required this.height,
    this.perceptualHash,
    this.audioFingerprint,
    this.date,
    this.time,
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
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || perceptualHash != null) {
      map['perceptual_hash'] = Variable<String>(perceptualHash);
    }
    if (!nullToAbsent || audioFingerprint != null) {
      map['audio_fingerprint'] = Variable<String>(audioFingerprint);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    if (!nullToAbsent || time != null) {
      map['time'] = Variable<String>(time);
    }
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
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      width: Value(width),
      height: Value(height),
      perceptualHash: perceptualHash == null && nullToAbsent
          ? const Value.absent()
          : Value(perceptualHash),
      audioFingerprint: audioFingerprint == null && nullToAbsent
          ? const Value.absent()
          : Value(audioFingerprint),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      time: time == null && nullToAbsent ? const Value.absent() : Value(time),
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
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      duration: serializer.fromJson<int?>(json['duration']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      perceptualHash: serializer.fromJson<String?>(json['perceptualHash']),
      audioFingerprint: serializer.fromJson<String?>(json['audioFingerprint']),
      date: serializer.fromJson<String?>(json['date']),
      time: serializer.fromJson<String?>(json['time']),
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
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'duration': serializer.toJson<int?>(duration),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'perceptualHash': serializer.toJson<String?>(perceptualHash),
      'audioFingerprint': serializer.toJson<String?>(audioFingerprint),
      'date': serializer.toJson<String?>(date),
      'time': serializer.toJson<String?>(time),
    };
  }

  MediaItem copyWith({
    int? id,
    String? fileHash,
    String? hashedFileName,
    String? mediaFolderPath,
    String? originalFileName,
    String? fileType,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    int? width,
    int? height,
    Value<String?> perceptualHash = const Value.absent(),
    Value<String?> audioFingerprint = const Value.absent(),
    Value<String?> date = const Value.absent(),
    Value<String?> time = const Value.absent(),
  }) => MediaItem(
    id: id ?? this.id,
    fileHash: fileHash ?? this.fileHash,
    hashedFileName: hashedFileName ?? this.hashedFileName,
    mediaFolderPath: mediaFolderPath ?? this.mediaFolderPath,
    originalFileName: originalFileName ?? this.originalFileName,
    fileType: fileType ?? this.fileType,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    duration: duration.present ? duration.value : this.duration,
    width: width ?? this.width,
    height: height ?? this.height,
    perceptualHash: perceptualHash.present
        ? perceptualHash.value
        : this.perceptualHash,
    audioFingerprint: audioFingerprint.present
        ? audioFingerprint.value
        : this.audioFingerprint,
    date: date.present ? date.value : this.date,
    time: time.present ? time.value : this.time,
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
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      duration: data.duration.present ? data.duration.value : this.duration,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      perceptualHash: data.perceptualHash.present
          ? data.perceptualHash.value
          : this.perceptualHash,
      audioFingerprint: data.audioFingerprint.present
          ? data.audioFingerprint.value
          : this.audioFingerprint,
      date: data.date.present ? data.date.value : this.date,
      time: data.time.present ? data.time.value : this.time,
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
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('audioFingerprint: $audioFingerprint, ')
          ..write('date: $date, ')
          ..write('time: $time')
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
    thumbnailPath,
    duration,
    width,
    height,
    perceptualHash,
    audioFingerprint,
    date,
    time,
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
          other.thumbnailPath == this.thumbnailPath &&
          other.duration == this.duration &&
          other.width == this.width &&
          other.height == this.height &&
          other.perceptualHash == this.perceptualHash &&
          other.audioFingerprint == this.audioFingerprint &&
          other.date == this.date &&
          other.time == this.time);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItem> {
  final Value<int> id;
  final Value<String> fileHash;
  final Value<String> hashedFileName;
  final Value<String> mediaFolderPath;
  final Value<String> originalFileName;
  final Value<String> fileType;
  final Value<String?> thumbnailPath;
  final Value<int?> duration;
  final Value<int> width;
  final Value<int> height;
  final Value<String?> perceptualHash;
  final Value<String?> audioFingerprint;
  final Value<String?> date;
  final Value<String?> time;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.hashedFileName = const Value.absent(),
    this.mediaFolderPath = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.fileType = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.perceptualHash = const Value.absent(),
    this.audioFingerprint = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    this.id = const Value.absent(),
    required String fileHash,
    required String hashedFileName,
    required String mediaFolderPath,
    required String originalFileName,
    required String fileType,
    this.thumbnailPath = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.perceptualHash = const Value.absent(),
    this.audioFingerprint = const Value.absent(),
    this.date = const Value.absent(),
    this.time = const Value.absent(),
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
    Expression<String>? thumbnailPath,
    Expression<int>? duration,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? perceptualHash,
    Expression<String>? audioFingerprint,
    Expression<String>? date,
    Expression<String>? time,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileHash != null) 'file_hash': fileHash,
      if (hashedFileName != null) 'hashed_file_name': hashedFileName,
      if (mediaFolderPath != null) 'media_folder_path': mediaFolderPath,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (fileType != null) 'file_type': fileType,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (perceptualHash != null) 'perceptual_hash': perceptualHash,
      if (audioFingerprint != null) 'audio_fingerprint': audioFingerprint,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
    });
  }

  MediaItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileHash,
    Value<String>? hashedFileName,
    Value<String>? mediaFolderPath,
    Value<String>? originalFileName,
    Value<String>? fileType,
    Value<String?>? thumbnailPath,
    Value<int?>? duration,
    Value<int>? width,
    Value<int>? height,
    Value<String?>? perceptualHash,
    Value<String?>? audioFingerprint,
    Value<String?>? date,
    Value<String?>? time,
  }) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      fileHash: fileHash ?? this.fileHash,
      hashedFileName: hashedFileName ?? this.hashedFileName,
      mediaFolderPath: mediaFolderPath ?? this.mediaFolderPath,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      perceptualHash: perceptualHash ?? this.perceptualHash,
      audioFingerprint: audioFingerprint ?? this.audioFingerprint,
      date: date ?? this.date,
      time: time ?? this.time,
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
    if (perceptualHash.present) {
      map['perceptual_hash'] = Variable<String>(perceptualHash.value);
    }
    if (audioFingerprint.present) {
      map['audio_fingerprint'] = Variable<String>(audioFingerprint.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
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
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('perceptualHash: $perceptualHash, ')
          ..write('audioFingerprint: $audioFingerprint, ')
          ..write('date: $date, ')
          ..write('time: $time')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $MediaTagsTable extends MediaTags
    with TableInfo<$MediaTagsTable, MediaTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [mediaId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId, tagId};
  @override
  MediaTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaTag(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $MediaTagsTable createAlias(String alias) {
    return $MediaTagsTable(attachedDatabase, alias);
  }
}

class MediaTag extends DataClass implements Insertable<MediaTag> {
  final int mediaId;
  final int tagId;
  const MediaTag({required this.mediaId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  MediaTagsCompanion toCompanion(bool nullToAbsent) {
    return MediaTagsCompanion(mediaId: Value(mediaId), tagId: Value(tagId));
  }

  factory MediaTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaTag(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  MediaTag copyWith({int? mediaId, int? tagId}) =>
      MediaTag(mediaId: mediaId ?? this.mediaId, tagId: tagId ?? this.tagId);
  MediaTag copyWithCompanion(MediaTagsCompanion data) {
    return MediaTag(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaTag(')
          ..write('mediaId: $mediaId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaTag &&
          other.mediaId == this.mediaId &&
          other.tagId == this.tagId);
}

class MediaTagsCompanion extends UpdateCompanion<MediaTag> {
  final Value<int> mediaId;
  final Value<int> tagId;
  final Value<int> rowid;
  const MediaTagsCompanion({
    this.mediaId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaTagsCompanion.insert({
    required int mediaId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       tagId = Value(tagId);
  static Insertable<MediaTag> custom({
    Expression<int>? mediaId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaTagsCompanion copyWith({
    Value<int>? mediaId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return MediaTagsCompanion(
      mediaId: mediaId ?? this.mediaId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaTagsCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingReviewsTable extends PendingReviews
    with TableInfo<$PendingReviewsTable, PendingReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingReviewsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uploadedItemIdMeta = const VerificationMeta(
    'uploadedItemId',
  );
  @override
  late final GeneratedColumn<int> uploadedItemId = GeneratedColumn<int>(
    'uploaded_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _matchedItemIdMeta = const VerificationMeta(
    'matchedItemId',
  );
  @override
  late final GeneratedColumn<int> matchedItemId = GeneratedColumn<int>(
    'matched_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _similarityPercentMeta = const VerificationMeta(
    'similarityPercent',
  );
  @override
  late final GeneratedColumn<double> similarityPercent =
      GeneratedColumn<double>(
        'similarity_percent',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uploadedItemId,
    matchedItemId,
    similarityPercent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uploaded_item_id')) {
      context.handle(
        _uploadedItemIdMeta,
        uploadedItemId.isAcceptableOrUnknown(
          data['uploaded_item_id']!,
          _uploadedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uploadedItemIdMeta);
    }
    if (data.containsKey('matched_item_id')) {
      context.handle(
        _matchedItemIdMeta,
        matchedItemId.isAcceptableOrUnknown(
          data['matched_item_id']!,
          _matchedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matchedItemIdMeta);
    }
    if (data.containsKey('similarity_percent')) {
      context.handle(
        _similarityPercentMeta,
        similarityPercent.isAcceptableOrUnknown(
          data['similarity_percent']!,
          _similarityPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_similarityPercentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uploadedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}uploaded_item_id'],
      )!,
      matchedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}matched_item_id'],
      )!,
      similarityPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}similarity_percent'],
      )!,
    );
  }

  @override
  $PendingReviewsTable createAlias(String alias) {
    return $PendingReviewsTable(attachedDatabase, alias);
  }
}

class PendingReview extends DataClass implements Insertable<PendingReview> {
  final int id;
  final int uploadedItemId;
  final int matchedItemId;
  final double similarityPercent;
  const PendingReview({
    required this.id,
    required this.uploadedItemId,
    required this.matchedItemId,
    required this.similarityPercent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uploaded_item_id'] = Variable<int>(uploadedItemId);
    map['matched_item_id'] = Variable<int>(matchedItemId);
    map['similarity_percent'] = Variable<double>(similarityPercent);
    return map;
  }

  PendingReviewsCompanion toCompanion(bool nullToAbsent) {
    return PendingReviewsCompanion(
      id: Value(id),
      uploadedItemId: Value(uploadedItemId),
      matchedItemId: Value(matchedItemId),
      similarityPercent: Value(similarityPercent),
    );
  }

  factory PendingReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingReview(
      id: serializer.fromJson<int>(json['id']),
      uploadedItemId: serializer.fromJson<int>(json['uploadedItemId']),
      matchedItemId: serializer.fromJson<int>(json['matchedItemId']),
      similarityPercent: serializer.fromJson<double>(json['similarityPercent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uploadedItemId': serializer.toJson<int>(uploadedItemId),
      'matchedItemId': serializer.toJson<int>(matchedItemId),
      'similarityPercent': serializer.toJson<double>(similarityPercent),
    };
  }

  PendingReview copyWith({
    int? id,
    int? uploadedItemId,
    int? matchedItemId,
    double? similarityPercent,
  }) => PendingReview(
    id: id ?? this.id,
    uploadedItemId: uploadedItemId ?? this.uploadedItemId,
    matchedItemId: matchedItemId ?? this.matchedItemId,
    similarityPercent: similarityPercent ?? this.similarityPercent,
  );
  PendingReview copyWithCompanion(PendingReviewsCompanion data) {
    return PendingReview(
      id: data.id.present ? data.id.value : this.id,
      uploadedItemId: data.uploadedItemId.present
          ? data.uploadedItemId.value
          : this.uploadedItemId,
      matchedItemId: data.matchedItemId.present
          ? data.matchedItemId.value
          : this.matchedItemId,
      similarityPercent: data.similarityPercent.present
          ? data.similarityPercent.value
          : this.similarityPercent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingReview(')
          ..write('id: $id, ')
          ..write('uploadedItemId: $uploadedItemId, ')
          ..write('matchedItemId: $matchedItemId, ')
          ..write('similarityPercent: $similarityPercent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, uploadedItemId, matchedItemId, similarityPercent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingReview &&
          other.id == this.id &&
          other.uploadedItemId == this.uploadedItemId &&
          other.matchedItemId == this.matchedItemId &&
          other.similarityPercent == this.similarityPercent);
}

class PendingReviewsCompanion extends UpdateCompanion<PendingReview> {
  final Value<int> id;
  final Value<int> uploadedItemId;
  final Value<int> matchedItemId;
  final Value<double> similarityPercent;
  const PendingReviewsCompanion({
    this.id = const Value.absent(),
    this.uploadedItemId = const Value.absent(),
    this.matchedItemId = const Value.absent(),
    this.similarityPercent = const Value.absent(),
  });
  PendingReviewsCompanion.insert({
    this.id = const Value.absent(),
    required int uploadedItemId,
    required int matchedItemId,
    required double similarityPercent,
  }) : uploadedItemId = Value(uploadedItemId),
       matchedItemId = Value(matchedItemId),
       similarityPercent = Value(similarityPercent);
  static Insertable<PendingReview> custom({
    Expression<int>? id,
    Expression<int>? uploadedItemId,
    Expression<int>? matchedItemId,
    Expression<double>? similarityPercent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uploadedItemId != null) 'uploaded_item_id': uploadedItemId,
      if (matchedItemId != null) 'matched_item_id': matchedItemId,
      if (similarityPercent != null) 'similarity_percent': similarityPercent,
    });
  }

  PendingReviewsCompanion copyWith({
    Value<int>? id,
    Value<int>? uploadedItemId,
    Value<int>? matchedItemId,
    Value<double>? similarityPercent,
  }) {
    return PendingReviewsCompanion(
      id: id ?? this.id,
      uploadedItemId: uploadedItemId ?? this.uploadedItemId,
      matchedItemId: matchedItemId ?? this.matchedItemId,
      similarityPercent: similarityPercent ?? this.similarityPercent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uploadedItemId.present) {
      map['uploaded_item_id'] = Variable<int>(uploadedItemId.value);
    }
    if (matchedItemId.present) {
      map['matched_item_id'] = Variable<int>(matchedItemId.value);
    }
    if (similarityPercent.present) {
      map['similarity_percent'] = Variable<double>(similarityPercent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingReviewsCompanion(')
          ..write('id: $id, ')
          ..write('uploadedItemId: $uploadedItemId, ')
          ..write('matchedItemId: $matchedItemId, ')
          ..write('similarityPercent: $similarityPercent')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $MediaTagsTable mediaTags = $MediaTagsTable(this);
  late final $PendingReviewsTable pendingReviews = $PendingReviewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mediaItems,
    tags,
    mediaTags,
    pendingReviews,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_reviews', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pending_reviews', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MediaItemsTableCreateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      required String fileHash,
      required String hashedFileName,
      required String mediaFolderPath,
      required String originalFileName,
      required String fileType,
      Value<String?> thumbnailPath,
      Value<int?> duration,
      Value<int> width,
      Value<int> height,
      Value<String?> perceptualHash,
      Value<String?> audioFingerprint,
      Value<String?> date,
      Value<String?> time,
    });
typedef $$MediaItemsTableUpdateCompanionBuilder =
    MediaItemsCompanion Function({
      Value<int> id,
      Value<String> fileHash,
      Value<String> hashedFileName,
      Value<String> mediaFolderPath,
      Value<String> originalFileName,
      Value<String> fileType,
      Value<String?> thumbnailPath,
      Value<int?> duration,
      Value<int> width,
      Value<int> height,
      Value<String?> perceptualHash,
      Value<String?> audioFingerprint,
      Value<String?> date,
      Value<String?> time,
    });

final class $$MediaItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItem> {
  $$MediaItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaTagsTable, List<MediaTag>>
  _mediaTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaTags,
    aliasName: $_aliasNameGenerator(db.mediaItems.id, db.mediaTags.mediaId),
  );

  $$MediaTagsTableProcessedTableManager get mediaTagsRefs {
    final manager = $$MediaTagsTableTableManager(
      $_db,
      $_db.mediaTags,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingReviewsTable, List<PendingReview>>
  _uploadedItemReviewsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingReviews,
    aliasName: $_aliasNameGenerator(
      db.mediaItems.id,
      db.pendingReviews.uploadedItemId,
    ),
  );

  $$PendingReviewsTableProcessedTableManager get uploadedItemReviews {
    final manager = $$PendingReviewsTableTableManager(
      $_db,
      $_db.pendingReviews,
    ).filter((f) => f.uploadedItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _uploadedItemReviewsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PendingReviewsTable, List<PendingReview>>
  _matchedItemReviewsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pendingReviews,
    aliasName: $_aliasNameGenerator(
      db.mediaItems.id,
      db.pendingReviews.matchedItemId,
    ),
  );

  $$PendingReviewsTableProcessedTableManager get matchedItemReviews {
    final manager = $$PendingReviewsTableTableManager(
      $_db,
      $_db.pendingReviews,
    ).filter((f) => f.matchedItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_matchedItemReviewsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaTagsRefs(
    Expression<bool> Function($$MediaTagsTableFilterComposer f) f,
  ) {
    final $$MediaTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaTags,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTagsTableFilterComposer(
            $db: $db,
            $table: $db.mediaTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> uploadedItemReviews(
    Expression<bool> Function($$PendingReviewsTableFilterComposer f) f,
  ) {
    final $$PendingReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingReviews,
      getReferencedColumn: (t) => t.uploadedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingReviewsTableFilterComposer(
            $db: $db,
            $table: $db.pendingReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> matchedItemReviews(
    Expression<bool> Function($$PendingReviewsTableFilterComposer f) f,
  ) {
    final $$PendingReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingReviews,
      getReferencedColumn: (t) => t.matchedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingReviewsTableFilterComposer(
            $db: $db,
            $table: $db.pendingReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
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

  GeneratedColumn<String> get perceptualHash => $composableBuilder(
    column: $table.perceptualHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioFingerprint => $composableBuilder(
    column: $table.audioFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  Expression<T> mediaTagsRefs<T extends Object>(
    Expression<T> Function($$MediaTagsTableAnnotationComposer a) f,
  ) {
    final $$MediaTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaTags,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> uploadedItemReviews<T extends Object>(
    Expression<T> Function($$PendingReviewsTableAnnotationComposer a) f,
  ) {
    final $$PendingReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingReviews,
      getReferencedColumn: (t) => t.uploadedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> matchedItemReviews<T extends Object>(
    Expression<T> Function($$PendingReviewsTableAnnotationComposer a) f,
  ) {
    final $$PendingReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pendingReviews,
      getReferencedColumn: (t) => t.matchedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PendingReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.pendingReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (MediaItem, $$MediaItemsTableReferences),
          MediaItem,
          PrefetchHooks Function({
            bool mediaTagsRefs,
            bool uploadedItemReviews,
            bool matchedItemReviews,
          })
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
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String?> perceptualHash = const Value.absent(),
                Value<String?> audioFingerprint = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
              }) => MediaItemsCompanion(
                id: id,
                fileHash: fileHash,
                hashedFileName: hashedFileName,
                mediaFolderPath: mediaFolderPath,
                originalFileName: originalFileName,
                fileType: fileType,
                thumbnailPath: thumbnailPath,
                duration: duration,
                width: width,
                height: height,
                perceptualHash: perceptualHash,
                audioFingerprint: audioFingerprint,
                date: date,
                time: time,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileHash,
                required String hashedFileName,
                required String mediaFolderPath,
                required String originalFileName,
                required String fileType,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String?> perceptualHash = const Value.absent(),
                Value<String?> audioFingerprint = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<String?> time = const Value.absent(),
              }) => MediaItemsCompanion.insert(
                id: id,
                fileHash: fileHash,
                hashedFileName: hashedFileName,
                mediaFolderPath: mediaFolderPath,
                originalFileName: originalFileName,
                fileType: fileType,
                thumbnailPath: thumbnailPath,
                duration: duration,
                width: width,
                height: height,
                perceptualHash: perceptualHash,
                audioFingerprint: audioFingerprint,
                date: date,
                time: time,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mediaTagsRefs = false,
                uploadedItemReviews = false,
                matchedItemReviews = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaTagsRefs) db.mediaTags,
                    if (uploadedItemReviews) db.pendingReviews,
                    if (matchedItemReviews) db.pendingReviews,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaTagsRefs)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          MediaTag
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._mediaTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (uploadedItemReviews)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          PendingReview
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._uploadedItemReviewsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).uploadedItemReviews,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.uploadedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (matchedItemReviews)
                        await $_getPrefetchedData<
                          MediaItem,
                          $MediaItemsTable,
                          PendingReview
                        >(
                          currentTable: table,
                          referencedTable: $$MediaItemsTableReferences
                              ._matchedItemReviewsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).matchedItemReviews,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (MediaItem, $$MediaItemsTableReferences),
      MediaItem,
      PrefetchHooks Function({
        bool mediaTagsRefs,
        bool uploadedItemReviews,
        bool matchedItemReviews,
      })
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaTagsTable, List<MediaTag>>
  _mediaTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.mediaTags.tagId),
  );

  $$MediaTagsTableProcessedTableManager get mediaTagsRefs {
    final manager = $$MediaTagsTableTableManager(
      $_db,
      $_db.mediaTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaTagsRefs(
    Expression<bool> Function($$MediaTagsTableFilterComposer f) f,
  ) {
    final $$MediaTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTagsTableFilterComposer(
            $db: $db,
            $table: $db.mediaTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> mediaTagsRefs<T extends Object>(
    Expression<T> Function($$MediaTagsTableAnnotationComposer a) f,
  ) {
    final $$MediaTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool mediaTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({mediaTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaTagsRefs) db.mediaTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, MediaTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._mediaTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).mediaTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool mediaTagsRefs})
    >;
typedef $$MediaTagsTableCreateCompanionBuilder =
    MediaTagsCompanion Function({
      required int mediaId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$MediaTagsTableUpdateCompanionBuilder =
    MediaTagsCompanion Function({
      Value<int> mediaId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$MediaTagsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaTagsTable, MediaTag> {
  $$MediaTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MediaItemsTable _mediaIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.mediaTags.mediaId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<int>('media_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.mediaTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaTagsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaTagsTable> {
  $$MediaTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MediaItemsTableFilterComposer get mediaId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaTagsTable> {
  $$MediaTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MediaItemsTableOrderingComposer get mediaId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaTagsTable> {
  $$MediaTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MediaItemsTableAnnotationComposer get mediaId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaTagsTable,
          MediaTag,
          $$MediaTagsTableFilterComposer,
          $$MediaTagsTableOrderingComposer,
          $$MediaTagsTableAnnotationComposer,
          $$MediaTagsTableCreateCompanionBuilder,
          $$MediaTagsTableUpdateCompanionBuilder,
          (MediaTag, $$MediaTagsTableReferences),
          MediaTag,
          PrefetchHooks Function({bool mediaId, bool tagId})
        > {
  $$MediaTagsTableTableManager(_$AppDatabase db, $MediaTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaTagsCompanion(
                mediaId: mediaId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int mediaId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => MediaTagsCompanion.insert(
                mediaId: mediaId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$MediaTagsTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$MediaTagsTableReferences
                                    ._mediaIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$MediaTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$MediaTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaTagsTable,
      MediaTag,
      $$MediaTagsTableFilterComposer,
      $$MediaTagsTableOrderingComposer,
      $$MediaTagsTableAnnotationComposer,
      $$MediaTagsTableCreateCompanionBuilder,
      $$MediaTagsTableUpdateCompanionBuilder,
      (MediaTag, $$MediaTagsTableReferences),
      MediaTag,
      PrefetchHooks Function({bool mediaId, bool tagId})
    >;
typedef $$PendingReviewsTableCreateCompanionBuilder =
    PendingReviewsCompanion Function({
      Value<int> id,
      required int uploadedItemId,
      required int matchedItemId,
      required double similarityPercent,
    });
typedef $$PendingReviewsTableUpdateCompanionBuilder =
    PendingReviewsCompanion Function({
      Value<int> id,
      Value<int> uploadedItemId,
      Value<int> matchedItemId,
      Value<double> similarityPercent,
    });

final class $$PendingReviewsTableReferences
    extends BaseReferences<_$AppDatabase, $PendingReviewsTable, PendingReview> {
  $$PendingReviewsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaItemsTable _uploadedItemIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(
          db.pendingReviews.uploadedItemId,
          db.mediaItems.id,
        ),
      );

  $$MediaItemsTableProcessedTableManager get uploadedItemId {
    final $_column = $_itemColumn<int>('uploaded_item_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_uploadedItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaItemsTable _matchedItemIdTable(_$AppDatabase db) =>
      db.mediaItems.createAlias(
        $_aliasNameGenerator(db.pendingReviews.matchedItemId, db.mediaItems.id),
      );

  $$MediaItemsTableProcessedTableManager get matchedItemId {
    final $_column = $_itemColumn<int>('matched_item_id')!;

    final manager = $$MediaItemsTableTableManager(
      $_db,
      $_db.mediaItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchedItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PendingReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingReviewsTable> {
  $$PendingReviewsTableFilterComposer({
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

  ColumnFilters<double> get similarityPercent => $composableBuilder(
    column: $table.similarityPercent,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaItemsTableFilterComposer get uploadedItemId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uploadedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableFilterComposer get matchedItemId {
    final $$MediaItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableFilterComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingReviewsTable> {
  $$PendingReviewsTableOrderingComposer({
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

  ColumnOrderings<double> get similarityPercent => $composableBuilder(
    column: $table.similarityPercent,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaItemsTableOrderingComposer get uploadedItemId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uploadedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableOrderingComposer get matchedItemId {
    final $$MediaItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingReviewsTable> {
  $$PendingReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get similarityPercent => $composableBuilder(
    column: $table.similarityPercent,
    builder: (column) => column,
  );

  $$MediaItemsTableAnnotationComposer get uploadedItemId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uploadedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaItemsTableAnnotationComposer get matchedItemId {
    final $$MediaItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedItemId,
      referencedTable: $db.mediaItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PendingReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingReviewsTable,
          PendingReview,
          $$PendingReviewsTableFilterComposer,
          $$PendingReviewsTableOrderingComposer,
          $$PendingReviewsTableAnnotationComposer,
          $$PendingReviewsTableCreateCompanionBuilder,
          $$PendingReviewsTableUpdateCompanionBuilder,
          (PendingReview, $$PendingReviewsTableReferences),
          PendingReview,
          PrefetchHooks Function({bool uploadedItemId, bool matchedItemId})
        > {
  $$PendingReviewsTableTableManager(
    _$AppDatabase db,
    $PendingReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> uploadedItemId = const Value.absent(),
                Value<int> matchedItemId = const Value.absent(),
                Value<double> similarityPercent = const Value.absent(),
              }) => PendingReviewsCompanion(
                id: id,
                uploadedItemId: uploadedItemId,
                matchedItemId: matchedItemId,
                similarityPercent: similarityPercent,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int uploadedItemId,
                required int matchedItemId,
                required double similarityPercent,
              }) => PendingReviewsCompanion.insert(
                id: id,
                uploadedItemId: uploadedItemId,
                matchedItemId: matchedItemId,
                similarityPercent: similarityPercent,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PendingReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({uploadedItemId = false, matchedItemId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (uploadedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.uploadedItemId,
                                    referencedTable:
                                        $$PendingReviewsTableReferences
                                            ._uploadedItemIdTable(db),
                                    referencedColumn:
                                        $$PendingReviewsTableReferences
                                            ._uploadedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (matchedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.matchedItemId,
                                    referencedTable:
                                        $$PendingReviewsTableReferences
                                            ._matchedItemIdTable(db),
                                    referencedColumn:
                                        $$PendingReviewsTableReferences
                                            ._matchedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PendingReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingReviewsTable,
      PendingReview,
      $$PendingReviewsTableFilterComposer,
      $$PendingReviewsTableOrderingComposer,
      $$PendingReviewsTableAnnotationComposer,
      $$PendingReviewsTableCreateCompanionBuilder,
      $$PendingReviewsTableUpdateCompanionBuilder,
      (PendingReview, $$PendingReviewsTableReferences),
      PendingReview,
      PrefetchHooks Function({bool uploadedItemId, bool matchedItemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$MediaTagsTableTableManager get mediaTags =>
      $$MediaTagsTableTableManager(_db, _db.mediaTags);
  $$PendingReviewsTableTableManager get pendingReviews =>
      $$PendingReviewsTableTableManager(_db, _db.pendingReviews);
}
